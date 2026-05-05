import { Router } from "express";
import { authMiddleware } from "../middlewares/authMiddleware.js";
import { requireRole } from "../middlewares/rbacMiddleware.js";
import * as admin from "../controllers/adminController.js";

const router = Router();

router.use(authMiddleware, requireRole("admin"));

router.get("/dashboard", admin.getDashboard);
router.get("/users", admin.listUsers);
router.get("/users/:id", admin.getUserById);
router.patch("/users/:id/role", admin.updateUserRole);

export default router;
