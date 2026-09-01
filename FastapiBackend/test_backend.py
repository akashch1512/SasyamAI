import asyncio

import httpx

from app.main import app


async def test_backend_suite():
    async with (
        app.router.lifespan_context(app),
        httpx.AsyncClient(
            transport=httpx.ASGITransport(app=app), base_url="http://test"
        ) as client,
    ):
        print("1. Testing Root & Health Check...")
        res = await client.get("/")
        assert res.status_code == 200
        print("   Root response:", res.json())

        res = await client.get("/api/health")
        assert res.status_code == 200

        print("2. Testing User Registration & Authentication...")
        register_payload = {
            "email": "farmer_test@sasyamai.com",
            "password": "FarmerPassword123!",
            "full_name": "Balwinder Singh",
            "phone_number": "+919876543299",
        }
        res = await client.post("/api/auth/register", json=register_payload)
        if res.status_code == 400:
            # Login if already registered
            res = await client.post(
                "/api/auth/login",
                json={
                    "email": "farmer_test@sasyamai.com",
                    "password": "FarmerPassword123!",
                },
            )
        assert res.status_code in [200, 201]
        data = res.json()
        token = data["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        print(f"   Logged in successfully as: {data['user']['full_name']}")

        print("3. Testing Farmer Onboarding...")
        onboarding_payload = {
            "phone_number": "+919876543299",
            "state": "Punjab",
            "district": "Ludhiana",
            "soil_type": "Alluvial Soil",
            "land_size_acres": 8.0,
            "irrigation_source": "Canal & Tubewell",
            "primary_crops": "Wheat, Rice",
            "preferred_language": "pa-IN",
        }
        res = await client.post(
            "/api/user/onboarding", json=onboarding_payload, headers=headers
        )
        assert res.status_code == 200
        user_profile = res.json()
        assert user_profile["is_onboarded"] is True
        print(
            f"   Onboarding complete: State={user_profile['state']}, Soil={user_profile['soil_type']}"
        )

        print("4. Testing LangGraph Chat Agent - Crop Recommendation...")
        chat_req = {
            "content": "What crops are best for my farm this coming winter season?",
        }
        res = await client.post(
            "/api/chat/message", json=chat_req, headers=headers
        )
        assert res.status_code == 200
        chat_res = res.json()
        session_id = chat_res["session_id"]
        print("   Agent response received:")
        print(f"   Session ID: {session_id}")
        print(f"   Content Preview:\n{chat_res['assistant_message']['content'][:200]}...\n")

        print("5. Testing LangGraph Chat Agent - Crop Price Query...")
        chat_req_price = {
            "session_id": session_id,
            "content": "What is the current mandi price of Wheat in Ludhiana?",
        }
        res = await client.post(
            "/api/chat/message", json=chat_req_price, headers=headers
        )
        assert res.status_code == 200
        price_res = res.json()
        assert "Mandi Price" in price_res["assistant_message"]["content"]
        print("   Price query response verified.")

        print("6. Testing LangGraph Chat Agent - Government Schemes...")
        chat_req_scheme = {
            "session_id": session_id,
            "content": "Are there any government subsidies for solar irrigation pumps?",
        }
        res = await client.post(
            "/api/chat/message", json=chat_req_scheme, headers=headers
        )
        assert res.status_code == 200
        scheme_res = res.json()
        assert "PM-KUSUM" in scheme_res["assistant_message"]["content"]
        print("   Government scheme response verified.")

        print("7. Testing LangGraph Chat Agent - Image-based Disease Detection...")
        chat_req_image = {
            "session_id": session_id,
            "content": "Please diagnose this tomato leaf condition.",
            "image_url": "https://example.com/test_leaf_blight.jpg",
        }
        res = await client.post(
            "/api/chat/message", json=chat_req_image, headers=headers
        )
        assert res.status_code == 200
        img_res = res.json()
        assert "Crop Disease Diagnosis Report" in img_res["assistant_message"]["content"]
        print("   Image disease detection subagent verified.")

        print("8. Testing Sarvam Speech-To-Text Route...")
        # Send a mock wav audio payload
        files = {"file": ("test_audio.wav", b"RIFF....WAVEfmt ....data....", "audio/wav")}
        data = {"language_code": "hi-IN"}
        res = await client.post(
            "/api/voice/transcribe", files=files, data=data, headers=headers
        )
        assert res.status_code == 200
        stt_res = res.json()
        print(f"   Transcribed text: '{stt_res['transcript']}' ({stt_res['detected_language']})")

        print("8b. Testing Sarvam Text-To-Speech Route...")
        tts_res = await client.post(
            "/api/voice/tts",
            json={"text": "Wheat is ready for harvest.", "language_code": "en-IN"},
            headers=headers,
        )
        assert tts_res.status_code == 200
        tts_body = tts_res.json()
        assert "audio_base64" in tts_body
        print(f"   TTS fallback={tts_body.get('is_fallback')} speaker={tts_body.get('speaker')}")

        print("9. Testing Admin Dashboard Login & Stats...")
        admin_login = await client.post(
            "/api/auth/login",
            json={"email": "admin@sasyamai.com", "password": "admin123"},
        )
        assert admin_login.status_code == 200
        admin_token = admin_login.json()["access_token"]
        admin_headers = {"Authorization": f"Bearer {admin_token}"}

        stats_res = await client.get("/api/admin/stats", headers=admin_headers)
        assert stats_res.status_code == 200
        stats = stats_res.json()
        print(f"   Admin Stats: Total Users={stats['total_users']}, Total Queries={stats['total_queries']}")

        insights_res = await client.get("/api/admin/insights", headers=admin_headers)
        assert insights_res.status_code == 200
        insights = insights_res.json()
        print(f"   Admin Insights: {insights['summary_headline']}")

        queries_res = await client.get(
            "/api/admin/queries-summary", headers=admin_headers
        )
        assert queries_res.status_code == 200
        print(f"   Admin Queries Log Count: {len(queries_res.json())}")

        print("\nAll Backend Tests Passed Successfully! 🎉\n")


if __name__ == "__main__":
    asyncio.run(test_backend_suite())
