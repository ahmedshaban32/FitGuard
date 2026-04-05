export function healthCheck(req, res) {
  res.json({
    ok: true,
    service: "fitguard-api",
    timestamp: new Date().toISOString(),
  });
}
