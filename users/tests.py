from rest_framework.test import APITestCase


class APISmokeTests(APITestCase):
    def test_register_goal_transaction_and_dashboard(self):
        register_res = self.client.post(
            "/auth/register",
            {
                "name": "Test User",
                "email": "test@example.com",
                "password": "StrongPass123",
                "password_confirm": "StrongPass123",
            },
            format="json",
        )
        self.assertEqual(register_res.status_code, 201)
        access = register_res.data["access"]

        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")

        goal_res = self.client.post("/goals", {"amount": "3000.00"}, format="json")
        self.assertEqual(goal_res.status_code, 201)

        tx_res = self.client.post(
            "/transactions",
            {"type": "income", "category": "Uber", "amount": "100.00", "note": "ok"},
            format="json",
        )
        self.assertEqual(tx_res.status_code, 201)

        dashboard_res = self.client.get("/dashboard/mobile")
        self.assertEqual(dashboard_res.status_code, 200)
        self.assertIn("daily_needed", dashboard_res.data)

    def test_invalid_category_for_type(self):
        register_res = self.client.post(
            "/auth/register",
            {
                "name": "Test User",
                "email": "test2@example.com",
                "password": "StrongPass123",
                "password_confirm": "StrongPass123",
            },
            format="json",
        )
        access = register_res.data["access"]
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
        self.client.post("/goals", {"amount": "3000.00"}, format="json")

        tx_res = self.client.post(
            "/transactions",
            {"type": "income", "category": "Combustível", "amount": "10.00"},
            format="json",
        )
        self.assertEqual(tx_res.status_code, 400)
