import { Router } from "express";
import { authMiddleware } from "../middlewares/authMiddleware.js";
import { requireRole } from "../middlewares/rbacMiddleware.js";
import * as exercises from "../controllers/exerciseController.js";

const router = Router();

router.get("/", exercises.listExercises);
router.post("/", authMiddleware, requireRole("admin"), exercises.createExercise);

export default router;
