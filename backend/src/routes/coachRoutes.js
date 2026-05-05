import { Router } from "express";
import { authMiddleware } from "../middlewares/authMiddleware.js";
import { requireRole } from "../middlewares/rbacMiddleware.js";
import * as coach from "../controllers/coachController.js";

const router = Router();

router.get("/public", coach.listPublicCoaches);
router.post("/applications", authMiddleware, requireRole("user"), coach.applyForCoach);
router.get("/applications", authMiddleware, requireRole("admin"), coach.listApplications);
router.patch(
  "/applications/:id/decision",
  authMiddleware,
  requireRole("admin"),
  coach.decideApplication
);

export default router;
