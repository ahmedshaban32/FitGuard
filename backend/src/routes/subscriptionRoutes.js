import { Router } from "express";
import { authMiddleware } from "../middlewares/authMiddleware.js";
import { requireRole } from "../middlewares/rbacMiddleware.js";
import * as subscriptions from "../controllers/subscriptionController.js";

const router = Router();

router.get("/me", authMiddleware, requireRole("user"), subscriptions.getMySubscription);
router.post("/", authMiddleware, requireRole("user"), subscriptions.subscribeCoach);
router.delete("/me", authMiddleware, requireRole("user"), subscriptions.cancelMySubscription);

export default router;
