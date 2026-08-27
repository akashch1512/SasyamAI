import logging
from pathlib import Path
from typing import Any

from langgraph.graph import END, StateGraph
from openai import AsyncOpenAI

from app.agent.state import AgentState
from app.agent.subagents.disease_detector import analyze_crop_disease_image
from app.agent.tools.crop_price import fetch_crop_market_price
from app.agent.tools.crop_recommendation import (
    check_missing_crop_recommendation_fields,
    predict_crops_ml,
)
from app.agent.tools.government_schemes import fetch_government_schemes
from app.config import settings

logger = logging.getLogger(__name__)

# Load Agronomy Guide Knowledge
ADVISORY_GUIDE_PATH = Path(__file__).parent / "knowledge" / "farm_advisory_guide.md"
AGRONOMY_KNOWLEDGE = ""
if ADVISORY_GUIDE_PATH.exists():
    AGRONOMY_KNOWLEDGE = ADVISORY_GUIDE_PATH.read_text(encoding="utf-8")


def detect_intent(user_text: str, has_image: bool) -> str:
    """Classify user intent based on query keywords and presence of image."""
    if has_image:
        return "disease_detection"

    text = user_text.lower()

    # 1. Scheme Intent
    scheme_keywords = [
        "scheme",
        "yojana",
        "subsid",
        "pm-kisan",
        "pm kisan",
        "kcc",
        "pmfby",
        "kusum",
        "government support",
        "grant",
        "subsidy",
        "sarkari",
    ]
    if any(k in text for k in scheme_keywords):
        return "government_schemes"

    # 2. Market / Mandi Price Intent
    price_keywords = [
        "price",
        "rate",
        "bhav",
        "mandi",
        "market rate",
        "cost per quintal",
        "msp",
        "market price",
        "current rate",
        "dam",
    ]
    if any(k in text for k in price_keywords):
        return "crop_price"

    # 3. Crop Recommendation Intent
    recommend_keywords = [
        "recommend",
        "suggest",
        "which crop",
        "what crop",
        "best crop",
        "crops are best",
        "crop to grow",
        "what to grow",
        "crop for my land",
        "suit my soil",
        "sow this season",
        "suitable crop",
        "selection",
        "fasan",
        "fasal",
        "crop recommendation",
    ]
    if any(k in text for k in recommend_keywords) or (
        ("best" in text or "good" in text or "which" in text or "what" in text)
        and ("crop" in text or "grow" in text or "sow" in text)
    ):
        return "crop_recommendation"

    # 4. Farm Advisory / Agronomy / Pest / Fertilizer Intent
    advisory_keywords = [
        "pest",
        "disease",
        "fertiliz",
        "npk",
        "urea",
        "dap",
        "potash",
        "organic",
        "irrigation",
        "soil",
        "yellow leaf",
        "spray",
        "fungicid",
        "insecticid",
        "treatment",
        "yield",
        "seed rate",
        "spacing",
        "pruning",
        "compost",
        "fym",
        "khad",
        "dawa",
        "rog",
        "keeda",
    ]
    if any(k in text for k in advisory_keywords):
        return "farm_advisory"

    return "general"


def extract_crop_entity(text: str) -> str | None:
    """Extract known crop name if mentioned in text."""
    common_crops = [
        "wheat",
        "paddy",
        "rice",
        "cotton",
        "soybean",
        "sugarcane",
        "maize",
        "tomato",
        "onion",
        "potato",
        "chilli",
        "mustard",
        "groundnut",
        "chickpea",
        "gram",
        "arhar",
        "tur",
        "moong",
        "urad",
        "bajra",
        "jowar",
        "ragi",
        "cucumber",
        "watermelon",
        "garlic",
        "ginger",
        "turmeric",
    ]
    lower = text.lower()
    for crop in common_crops:
        if crop in lower:
            return crop.capitalize()
    return None


# --- LangGraph Nodes ---


async def router_node(state: AgentState) -> dict[str, Any]:
    """Inspect input and determine execution route."""
    user_msg = state.get("current_user_message", "")
    image_url = state.get("image_url")
    has_image = bool(image_url and image_url.strip())

    intent = detect_intent(user_msg, has_image)
    detected_crop = extract_crop_entity(user_msg)

    logger.info(f"[ROUTER] Intent detected: {intent} (crop: {detected_crop})")
    return {
        "intent": intent,
        "detected_crop": detected_crop,
    }


async def disease_detection_node(state: AgentState) -> dict[str, Any]:
    """Execute specialized ChatGPT Vision sub-agent for crop leaf diagnosis."""
    image_url = state.get("image_url", "")
    user_msg = state.get("current_user_message", "")

    diagnosis = await analyze_crop_disease_image(image_url, user_msg)
    crop_name = diagnosis.get("crop_name", "Crop")
    disease_name = diagnosis.get("disease_name", "Condition")

    # Format structured farmer-friendly response
    symptoms = "\n".join([f"• {s}" for s in diagnosis.get("symptoms_observed", [])])
    chemical = "\n".join([f"1. {c}" for c in diagnosis.get("chemical_treatment", [])])
    organic = "\n".join([f"• {o}" for o in diagnosis.get("organic_treatment", [])])
    prevention = "\n".join(
        [f"• {p}" for p in diagnosis.get("preventative_measures", [])]
    )

    response_text = f"""### 🌾 Crop Disease Diagnosis Report

**Crop:** {crop_name}
**Identified Issue:** **{disease_name}**
**Confidence:** {diagnosis.get("confidence", "High")} | **Severity:** {diagnosis.get("severity_level", "Moderate")}

---

#### 🔍 Symptoms Observed:
{symptoms}

#### 📋 Summary:
{diagnosis.get("summary", "")}

---

#### 🧪 Recommended Immediate Treatment (Chemical):
{chemical}

#### 🌿 Organic & Eco-Friendly Alternatives:
{organic}

#### 🛡️ Preventive Farm Practices:
{prevention}

> *Tip: Always wear protective gear when spraying and test treatments on a small plot first.*
"""

    suggested = [
        f"How to apply organic spray for {crop_name}?",
        f"What fertilizer to use after {disease_name} recovery?",
        "What is the best irrigation schedule?",
    ]

    return {
        "disease_analysis_result": diagnosis,
        "detected_crop": crop_name,
        "detected_disease": disease_name,
        "final_response": response_text,
        "suggested_actions": suggested,
    }


async def crop_recommendation_node(state: AgentState) -> dict[str, Any]:
    """Recommend crops using ML model placeholder and farmer profile context."""
    profile = state.get("user_profile", {})
    user_msg = state.get("current_user_message", "")

    # Check if important profile details are missing
    missing = check_missing_crop_recommendation_fields(profile)

    # If missing critical info and user didn't mention it in the prompt
    soil = profile.get("soil_type")
    state_loc = profile.get("state") or profile.get("district")
    irrigation = profile.get("irrigation_source")

    # Check if user mentioned soil or state in their message
    msg_lower = user_msg.lower()
    if not soil:
        for s in ["black", "alluvial", "red", "sandy", "clay", "loam", "laterite"]:
            if s in msg_lower:
                soil = f"{s.capitalize()} Soil"
                break
    if not state_loc:
        for st in [
            "maharashtra",
            "punjab",
            "haryana",
            "uttar pradesh",
            "gujarat",
            "madhya pradesh",
            "karnataka",
            "andhra pradesh",
            "telangana",
            "tamil nadu",
            "rajasthan",
            "bihar",
            "west bengal",
        ]:
            if st in msg_lower:
                state_loc = st.title()
                break

    # If still missing critical data, ask clarifying questions first
    if not soil and not state_loc:
        clarification_text = """### 🌱 SasyamAI Crop Recommendation

To give you the most accurate and profitable crop recommendations tailored specifically to your farm, I need a few details:

1. **What type of soil do you have?** *(e.g., Black soil, Alluvial soil, Red soil, Sandy loam)*
2. **Where is your farm located?** *(State & District)*
3. **What is your water/irrigation source?** *(e.g., Canal, Borewell, Rainfed, Drip)*

💡 *You can also update these directly in your **Profile** so I always remember them!*
"""
        return {
            "missing_fields": missing,
            "final_response": clarification_text,
            "suggested_actions": [
                "I have Black Soil in Maharashtra with Borewell",
                "I have Alluvial Soil in Punjab",
                "Update my profile",
            ],
        }

    # Run ML Model Inference Interface (Placeholder)
    ml_result = predict_crops_ml(
        soil_type=soil,
        state=state_loc,
        irrigation_source=irrigation,
        land_size_acres=profile.get("land_size_acres"),
    )

    top_crops = ml_result.get("top_crops", ["Wheat", "Gram", "Mustard"])

    # Synthesize comprehensive recommendation with reasoning
    recommendation_text = f"""### 🌾 Recommended Crops for Your Farm

Based on your farm profile (**Location:** {state_loc or "Regional zone"}, **Soil:** {soil or "Standard agricultural soil"}, **Irrigation:** {irrigation or "Borewell/Canal"}):

#### Top Suitable Crops:
"""
    for i, crop in enumerate(top_crops, 1):
        recommendation_text += f"\n**{i}. {crop}**"
        if "Cotton" in crop:
            recommendation_text += "\n   - *Sowing Window:* May – June | *Expected Yield:* 8–12 Quintals/acre"
            recommendation_text += "\n   - *Why Suitable:* Thrives in deep moisture-retentive black soil with good drainage."
        elif "Wheat" in crop:
            recommendation_text += "\n   - *Sowing Window:* Nov 1 – Nov 25 | *Expected Yield:* 18–22 Quintals/acre"
            recommendation_text += "\n   - *Why Suitable:* Excellent response to alluvial and fertile loam under cool winter conditions."
        elif "Soybean" in crop:
            recommendation_text += "\n   - *Sowing Window:* Late June to July | *Expected Yield:* 8–10 Quintals/acre"
            recommendation_text += "\n   - *Why Suitable:* Enriches soil with atmospheric nitrogen and fits Kharif crop rotations."
        elif "Groundnut" in crop:
            recommendation_text += "\n   - *Sowing Window:* June – July / Jan – Feb | *Expected Yield:* 10–14 Quintals/acre"
            recommendation_text += "\n   - *Why Suitable:* Light and well-drained soil promotes healthy pod development."
        elif "Mustard" in crop:
            recommendation_text += (
                "\n   - *Sowing Window:* October | *Expected Yield:* 6–8 Quintals/acre"
            )
            recommendation_text += "\n   - *Why Suitable:* Low water requirement crop ideal for Rabi season."
        else:
            recommendation_text += "\n   - *Agronomic Note:* Recommended for high return under proper nutrient management."

    recommendation_text += """

---

#### 💡 Agronomic Best Practices:
• **Soil Preparation:** Incorporate 5–8 tonnes/acre of well-decomposed Farm Yard Manure (FYM) or compost.
• **Seed Treatment:** Treat seeds with *Trichoderma viride* (5g/kg) and *Rhizobium/Azotobacter* bio-fertilizers before sowing.
• **Water Management:** Plan for micro-irrigation (Drip/Sprinkler) to maximize water efficiency and crop quality.
"""

    return {
        "ml_prediction_result": ml_result,
        "detected_crop": top_crops[0] if top_crops else None,
        "final_response": recommendation_text,
        "suggested_actions": [
            f"What is the fertilizer schedule for {top_crops[0]}?",
            "How much seed is needed per acre?",
            "Recommend organic pest control",
        ],
    }


async def crop_price_node(state: AgentState) -> dict[str, Any]:
    """Handle crop market / mandi price queries."""
    crop = state.get("detected_crop") or "your crop"
    fetch_crop_market_price(crop_name=crop)

    response_text = f"""### 📊 Real-Time Mandi Prices

**Requested Commodity:** {crop}

This feature is not implemented yet, but it will be available soon. :)

> *In the meantime, you can check official local APMC rates on the central Agmarknet portal (agmarknet.gov.in) or your state agricultural marketing board.*
"""
    return {
        "crop_price_result": "not_implemented",
        "final_response": response_text,
        "suggested_actions": [
            "Recommend suitable crops instead",
            "How to increase crop yield?",
            "Pest control tips",
        ],
    }


async def government_schemes_node(state: AgentState) -> dict[str, Any]:
    """Handle central and state agricultural government schemes."""
    profile = state.get("user_profile", {})
    state_loc = profile.get("state")
    fetch_government_schemes(state=state_loc)

    response_text = """### 🏛️ Government Agricultural Schemes & Subsidies

This feature is not implemented yet, but it will be available soon. :)

> *Key national schemes you can explore in the meantime:*
> • **PM-KISAN:** Direct income support of ₹6,000/year for landholding farmer families.
> • **PMFBY (Crop Insurance):** Comprehensive insurance coverage against non-preventable natural risks.
> • **Kisan Credit Card (KCC):** Concessional credit for agricultural inputs and machinery.
> • **PM-KUSUM:** Subsidies for solar-powered agricultural irrigation pumps.
"""
    return {
        "government_schemes_result": "not_implemented",
        "final_response": response_text,
        "suggested_actions": [
            "Crop recommendation for my land",
            "How to test soil health?",
            "Check disease symptoms",
        ],
    }


async def farm_advisory_node(state: AgentState) -> dict[str, Any]:
    """Provide agricultural guidance using the agronomy knowledge base and LLM."""
    user_msg = state.get("current_user_message", "")
    profile = state.get("user_profile", {})

    # If OpenAI API is available, generate dynamic response with knowledge context
    if settings.OPENAI_API_KEY:
        try:
            client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
            prompt = f"""You are SasyamAI, an empathetic and expert agricultural assistant helping Indian farmers.
Farmer Profile: Location={profile.get("state", "India")}, Soil={profile.get("soil_type", "Agricultural")}, Land={profile.get("land_size_acres", "N/A")} acres.

Agronomy Reference Knowledge:
{AGRONOMY_KNOWLEDGE}

Farmer's Question: {user_msg}

Provide a clear, practical, structured, and farmer-friendly answer in markdown format. Use bullet points and highlight exact dosages and timings."""

            llm_res = await client.chat.completions.create(
                model=settings.OPENAI_MODEL,
                messages=[{"role": "user", "content": prompt}],
                max_tokens=settings.MAX_OUTPUT_TOKEN,
                temperature=0.3,
            )
            response_text = llm_res.choices[0].message.content or ""
            if response_text:
                return {
                    "advisory_context": "llm_generated",
                    "final_response": response_text,
                    "suggested_actions": [
                        "What organic alternatives can I use?",
                        "When is the next irrigation needed?",
                        "What is the best harvesting time?",
                    ],
                }
        except Exception as e:  # noqa: BLE001
            logger.error(f"[FARM_ADVISORY] OpenAI call failed: {e}")

    # Fallback Agronomic Guidance
    response_text = """### 🌾 Farm Advisory & Agronomic Guidance

Here is practical agricultural guidance for your query:

#### 1. Integrated Nutrient Management:
• **Soil Enrichment:** Apply 5–10 tonnes/acre of well-rotted FYM or 2 tonnes/acre Vermicompost during land preparation.
• **Balanced Fertilizers:** Maintain balanced N:P:K ratios (4:2:1 for cereals, 1:2:1 for pulses). Split nitrogen applications into 2–3 top dressings.
• **Bio-fertilizers:** Seed treatment with *Azotobacter* / *Rhizobium* and *PSB* (Phosphate Solubilizing Bacteria) saves 20–25% chemical fertilizer.

#### 2. Eco-Friendly Pest & Disease Protection:
• Install **Yellow and Blue sticky traps** (10–12 traps/acre) to control sucking pests like whiteflies, aphids, and thrips.
• Spray **Neem Oil 10,000 ppm** @ 2–3 ml/L with soap water at the first sign of pest infestation.
• Use *Trichoderma viride* @ 2.5 kg/acre mixed in FYM for root protection against fungal wilts.

#### 3. Water Efficiency:
• Use drip or sprinkler irrigation to deliver water directly to root zones and avoid fungal leaf diseases caused by wet foliage.
"""
    return {
        "advisory_context": "rule_based_guide",
        "final_response": response_text,
        "suggested_actions": [
            "How to prepare Jeevamrutha at home?",
            "Pest management schedule",
            "Recommend crops for next season",
        ],
    }


async def general_chat_node(state: AgentState) -> dict[str, Any]:
    """Handle greetings and general agricultural conversations."""
    user_msg = state.get("current_user_message", "")
    profile = state.get("user_profile", {})
    name = profile.get("full_name") or "Farmer"

    if settings.OPENAI_API_KEY:
        try:
            client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
            llm_res = await client.chat.completions.create(
                model=settings.OPENAI_MODEL,
                messages=[
                    {
                        "role": "system",
                        "content": "You are SasyamAI, a friendly, concise, and helpful AI assistant for Indian farmers. Always be respectful, practical, and clear.",
                    },
                    {"role": "user", "content": user_msg},
                ],
                max_tokens=settings.MAX_OUTPUT_TOKEN,
                temperature=0.5,
            )
            content = llm_res.choices[0].message.content
            if content:
                return {
                    "final_response": content,
                    "suggested_actions": [
                        "Recommend crops for my farm",
                        "Diagnose a plant disease from photo",
                        "Farming tips for this season",
                    ],
                }
        except Exception as e:  # noqa: BLE001
            logger.error(f"[GENERAL_CHAT] OpenAI call failed: {e}")

    response_text = f"""Namaste {name}! 🙏

I am **SasyamAI**, your dedicated agricultural assistant. Here is what I can help you with:

1. 🌾 **Crop Recommendations:** Suggest the most profitable crops for your specific soil and region.
2. 📸 **Disease Detection:** Upload a photo of an affected leaf or plant for instant AI diagnosis and treatment plans.
3. 🌿 **Farm Advisory & Pest Control:** Get practical dosage, organic solutions, and irrigation advice.
4. 📊 **Mandi Prices & Government Schemes:** Stay updated with agricultural market information.

How can I assist your farm today?
"""
    return {
        "final_response": response_text,
        "suggested_actions": [
            "Recommend crops for my farm",
            "Check crop disease",
            "How to improve soil fertility?",
        ],
    }


# --- Conditional Routing Function ---


def route_by_intent(state: AgentState) -> str:
    intent = state.get("intent", "general")
    if intent == "disease_detection":
        return "disease_detection_node"
    elif intent == "crop_recommendation":
        return "crop_recommendation_node"
    elif intent == "crop_price":
        return "crop_price_node"
    elif intent == "government_schemes":
        return "government_schemes_node"
    elif intent == "farm_advisory":
        return "farm_advisory_node"
    return "general_chat_node"


# --- Build & Compile LangGraph Workflow ---


def build_sasyamai_agent():
    workflow = StateGraph(AgentState)

    # Add Nodes
    workflow.add_node("router_node", router_node)
    workflow.add_node("disease_detection_node", disease_detection_node)
    workflow.add_node("crop_recommendation_node", crop_recommendation_node)
    workflow.add_node("crop_price_node", crop_price_node)
    workflow.add_node("government_schemes_node", government_schemes_node)
    workflow.add_node("farm_advisory_node", farm_advisory_node)
    workflow.add_node("general_chat_node", general_chat_node)

    # Set Entry Point
    workflow.set_entry_point("router_node")

    # Add Conditional Edges from router
    workflow.add_conditional_edges(
        "router_node",
        route_by_intent,
        {
            "disease_detection_node": "disease_detection_node",
            "crop_recommendation_node": "crop_recommendation_node",
            "crop_price_node": "crop_price_node",
            "government_schemes_node": "government_schemes_node",
            "farm_advisory_node": "farm_advisory_node",
            "general_chat_node": "general_chat_node",
        },
    )

    # Connect all leaf nodes to END
    workflow.add_edge("disease_detection_node", END)
    workflow.add_edge("crop_recommendation_node", END)
    workflow.add_edge("crop_price_node", END)
    workflow.add_edge("government_schemes_node", END)
    workflow.add_edge("farm_advisory_node", END)
    workflow.add_edge("general_chat_node", END)

    return workflow.compile()


# Compiled Singleton Graph
sasyamai_graph = build_sasyamai_agent()


async def run_sasyamai_agent(
    user_message: str,
    user_profile: dict[str, Any],
    image_url: str | None = None,
    chat_history: list[dict[str, Any]] | None = None,
) -> dict[str, Any]:
    """Execute the SasyamAI LangGraph agent with the provided user message and context."""
    initial_state: AgentState = {
        "current_user_message": user_message,
        "image_url": image_url,
        "user_profile": user_profile,  # type: ignore
        "messages": chat_history or [],
        "missing_fields": [],
        "suggested_actions": [],
    }

    result = await sasyamai_graph.ainvoke(initial_state)
    return result
