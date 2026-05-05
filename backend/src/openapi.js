/**
 * OpenAPI 3.0 spec — edit here as you add routes.
 * UI: GET /api-docs   |   Raw JSON: GET /openapi.json
 */
export const openApiSpec = {
  openapi: "3.0.3",
  info: {
    title: "FitGuard API",
    version: "0.2.0",
    description: "Backend for FitGuard (auth, coaching, plans, progress). Base path: `/api`.",
  },
  servers: [{ url: "/", description: "This server" }],
  tags: [
    { name: "Health", description: "Liveness" },
    { name: "Auth", description: "Registration and JWT" },
    { name: "Users", description: "Profile and AI free-tier plan" },
    { name: "Coaches", description: "Coach applications and listing" },
    { name: "Subscriptions", description: "Monthly coach subscriptions" },
    { name: "Exercises", description: "Tracked and guided exercise catalog" },
    { name: "Workouts", description: "Assigned workout and nutrition plans" },
    { name: "Progress", description: "Workout sessions and CV stats" },
  ],
  components: {
    securitySchemes: {
      bearerAuth: { type: "http", scheme: "bearer", bearerFormat: "JWT" },
    },
    schemas: {
      Error: {
        type: "object",
        properties: {
          error: {
            type: "object",
            properties: {
              code: { type: "string", example: "VALIDATION_ERROR" },
              message: { type: "string", example: "Invalid input" },
            },
          },
        },
      },
      User: {
        type: "object",
        properties: {
          id: { type: "string" },
          email: { type: "string", format: "email" },
          role: { type: "string", enum: ["user", "trainer", "admin"] },
          profile: { $ref: "#/components/schemas/UserProfile" },
          emailVerifiedAt: { type: "string", format: "date-time", nullable: true },
        },
      },
      UserProfile: {
        type: "object",
        properties: {
          name: { type: "string", nullable: true },
          heightCm: { type: "number", nullable: true },
          weightKg: { type: "number", nullable: true },
          goal: {
            type: "string",
            nullable: true,
            enum: ["fat_loss", "muscle_gain", "mobility", "general_fitness"],
          },
        },
      },
      RegisterBody: {
        type: "object",
        required: ["email", "password"],
        properties: {
          email: { type: "string", format: "email" },
          password: { type: "string", format: "password", minLength: 8 },
          role: { type: "string", enum: ["user", "trainer"], default: "user" },
          name: { type: "string" },
        },
      },
      LoginBody: {
        type: "object",
        required: ["email", "password"],
        properties: {
          email: { type: "string", format: "email" },
          password: { type: "string", format: "password" },
        },
      },
      Exercise: {
        type: "object",
        properties: {
          _id: { type: "string" },
          name: { type: "string" },
          type: { type: "string", enum: ["tracked", "guided"] },
          instructions: { type: "string" },
          isActive: { type: "boolean" },
        },
      },
      PlanAssignment: {
        type: "object",
        properties: {
          _id: { type: "string" },
          userId: { type: "string" },
          assignedBy: { type: "string" },
          source: { type: "string", enum: ["ai", "coach"] },
          workoutPlan: { type: "array", items: { type: "string" } },
          nutritionPlan: { type: "array", items: { type: "string" } },
          notes: { type: "string" },
          active: { type: "boolean" },
        },
      },
      Subscription: {
        type: "object",
        properties: {
          _id: { type: "string" },
          userId: { type: "string" },
          coachId: { type: "string" },
          startDate: { type: "string", format: "date-time" },
          endDate: { type: "string", format: "date-time" },
          status: { type: "string", enum: ["active", "cancelled", "expired"] },
        },
      },
      WorkoutSession: {
        type: "object",
        properties: {
          _id: { type: "string" },
          userId: { type: "string" },
          exerciseId: { type: "string" },
          tracked: { type: "boolean" },
          totalReps: { type: "number" },
          correctReps: { type: "number" },
          wrongReps: { type: "number" },
          mistakes: {
            type: "array",
            items: {
              type: "object",
              properties: { type: { type: "string" }, count: { type: "number" } },
            },
          },
          sessionAt: { type: "string", format: "date-time" },
        },
      },
    },
  },
  paths: {
    "/api/health": { get: { tags: ["Health"], summary: "Health check", responses: { 200: { description: "OK" } } } },
    "/api/auth/register": {
      post: {
        tags: ["Auth"],
        summary: "Register",
        requestBody: { required: true, content: { "application/json": { schema: { $ref: "#/components/schemas/RegisterBody" } } } },
        responses: { 201: { description: "Created" }, 400: { description: "Validation", content: { "application/json": { schema: { $ref: "#/components/schemas/Error" } } } } },
      },
    },
    "/api/auth/login": {
      post: {
        tags: ["Auth"],
        summary: "Login",
        requestBody: { required: true, content: { "application/json": { schema: { $ref: "#/components/schemas/LoginBody" } } } },
        responses: { 200: { description: "JWT + user" }, 401: { description: "Invalid credentials" } },
      },
    },
    "/api/auth/me": { get: { tags: ["Auth"], summary: "Current user", security: [{ bearerAuth: [] }], responses: { 200: { description: "Profile" }, 401: { description: "Unauthorized" } } } },
    "/api/users/me/profile": {
      get: { tags: ["Users"], summary: "Get current user profile", security: [{ bearerAuth: [] }], responses: { 200: { description: "Profile" } } },
      patch: {
        tags: ["Users"],
        summary: "Update current user profile",
        security: [{ bearerAuth: [] }],
        requestBody: { required: true, content: { "application/json": { schema: { $ref: "#/components/schemas/UserProfile" } } } },
        responses: { 200: { description: "Profile updated" } },
      },
    },
    "/api/users/me/ai-plan": { post: { tags: ["Users"], summary: "Generate free-tier AI plan (stub)", security: [{ bearerAuth: [] }], responses: { 201: { description: "Plan generated" } } } },
    "/api/coaches/public": { get: { tags: ["Coaches"], summary: "List approved coaches", responses: { 200: { description: "Coach list" } } } },
    "/api/coaches/applications": {
      post: { tags: ["Coaches"], summary: "Apply to become coach (user role)", security: [{ bearerAuth: [] }], responses: { 201: { description: "Application submitted" } } },
      get: { tags: ["Coaches"], summary: "List pending coach applications (admin)", security: [{ bearerAuth: [] }], responses: { 200: { description: "Pending applications" } } },
    },
    "/api/coaches/applications/{id}/decision": {
      patch: {
        tags: ["Coaches"],
        summary: "Approve/reject coach application (admin)",
        security: [{ bearerAuth: [] }],
        parameters: [{ in: "path", name: "id", required: true, schema: { type: "string" } }],
        responses: { 200: { description: "Decision recorded" } },
      },
    },
    "/api/subscriptions/me": {
      get: { tags: ["Subscriptions"], summary: "Get my active subscription", security: [{ bearerAuth: [] }], responses: { 200: { description: "Subscription or null" } } },
      delete: { tags: ["Subscriptions"], summary: "Cancel my active subscription", security: [{ bearerAuth: [] }], responses: { 200: { description: "Cancelled" } } },
    },
    "/api/subscriptions": {
      post: {
        tags: ["Subscriptions"],
        summary: "Subscribe to one coach for one month",
        security: [{ bearerAuth: [] }],
        requestBody: { required: true, content: { "application/json": { schema: { type: "object", required: ["coachId"], properties: { coachId: { type: "string" } } } } } },
        responses: { 201: { description: "Subscribed" }, 409: { description: "Already subscribed" } },
      },
    },
    "/api/exercises": {
      get: { tags: ["Exercises"], summary: "List active exercises", parameters: [{ in: "query", name: "type", schema: { type: "string", enum: ["tracked", "guided"] } }], responses: { 200: { description: "Exercise list" } } },
      post: { tags: ["Exercises"], summary: "Create exercise (admin)", security: [{ bearerAuth: [] }], responses: { 201: { description: "Exercise created" } } },
    },
    "/api/workouts/me/plan": { get: { tags: ["Workouts"], summary: "Get my current active plan", security: [{ bearerAuth: [] }], responses: { 200: { description: "Plan or null" } } } },
    "/api/workouts/coach/assignments": { post: { tags: ["Workouts"], summary: "Coach assigns plan to subscribed user", security: [{ bearerAuth: [] }], responses: { 201: { description: "Plan assigned" } } } },
    "/api/progress/sessions": { post: { tags: ["Progress"], summary: "Log workout session with tracked stats", security: [{ bearerAuth: [] }], responses: { 201: { description: "Session logged" } } } },
    "/api/progress/me": { get: { tags: ["Progress"], summary: "Get progress summary and recent sessions", security: [{ bearerAuth: [] }], responses: { 200: { description: "Progress data" } } } },
  },
};
