import { connectDb } from "./database.js";
import { env } from "./config.js";
import { createApp } from "./app.js";

async function main() {
  await connectDb();
  const app = createApp();
  app.listen(env.port, () => {
    console.log(`FitGuard API listening on port ${env.port}`);
  });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
