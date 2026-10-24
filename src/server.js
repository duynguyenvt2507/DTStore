require('dotenv').config();
const mysql = require('mysql2/promise');
const { createApp } = require('./app');
const { createMySqlProductsRepository } = require('./repositories/mysqlProductsRepository');

function requiredEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

async function bootstrap() {
  const pool = mysql.createPool({
    host: requiredEnv('DB_HOST'),
    port: Number(process.env.DB_PORT || 3306),
    user: requiredEnv('DB_USER'),
    password: requiredEnv('DB_PASSWORD'),
    database: requiredEnv('DB_NAME'),
    waitForConnections: true,
    connectionLimit: Number(process.env.DB_CONNECTION_LIMIT || 10),
    queueLimit: 0,
    decimalNumbers: true,
  });

  const repository = createMySqlProductsRepository(pool);
  const app = createApp({ productsRepository: repository });

  const port = Number(process.env.PORT || 3000);
  app.listen(port, () => {
    // eslint-disable-next-line no-console
    console.log(`DTStore Product Catalog API listening on port ${port}`);
  });
}

bootstrap().catch((error) => {
  // eslint-disable-next-line no-console
  console.error(error.message);
  process.exit(1);
});
