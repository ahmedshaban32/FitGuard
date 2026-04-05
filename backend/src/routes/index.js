import { Router } from "express";
import * as health from "../controllers/healthController.js";
import authRoutes from "./authRoutes.js";

const router = Router();

router.get("/health", health.healthCheck);
router.use("/auth", authRoutes);

export default router;
