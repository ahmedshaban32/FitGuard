import { Router } from "express";
import * as auth from "../controllers/authController.js";
import { authMiddleware } from "../middlewares/authMiddleware.js";

const router = Router();

router.post("/register", auth.register);
router.post("/login", auth.login);
router.get("/me", authMiddleware, auth.me);

export default router;
