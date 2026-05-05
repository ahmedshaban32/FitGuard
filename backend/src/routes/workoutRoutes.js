import { Router } from "express";
import { authMiddleware } from "../middlewares/authMiddleware.js";
import { requireRole } from "../middlewares/rbacMiddleware.js";
import * as workouts from "../controllers/workoutController.js";

const router = Router();

router.get("/me/plan", authMiddleware, workouts.getMyCurrentPlan);
router.post(
  "/coach/assignments",
  authMiddleware,
  requireRole("trainer"),
  workouts.assignPlanToSubscribedUser
);

export default router;
