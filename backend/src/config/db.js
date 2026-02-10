import { Sequelize } from 'sequelize';
import AWS from 'aws-sdk';

// Configure AWS SDK region
AWS.config.update({ region: process.env.AWS_REGION });

const secretsManager = new AWS.SecretsManager();

// Function to get DB credentials from Secrets Manager
async function getDbCredentials(secretName) {
  const data = await secretsManager.getSecretValue({ SecretId: secretName }).promise();

  if ('SecretString' in data) {
    return JSON.parse(data.SecretString);
  }

  throw new Error('Secret has no string value');
}

// Initialize Sequelize with dynamic credentials
async function initSequelize() {
  const secretName = process.env.DB_SECRET_NAME;
  const creds = await getDbCredentials(secretName);

  const sequelize = new Sequelize(
    creds.dbname,  // database name first
    creds.username,
    creds.password,
    {
      host: creds.host,
      port: creds.port,
      dialect: 'mysql',
      logging: process.env.NODE_ENV === 'development' ? console.log : false,
      pool: {
        max: 10,
        min: 0,
        acquire: 30000,
        idle: 10000
      },
      define: {
        timestamps: true,
        underscored: true,
        freezeTableName: true
      }
    }
  );

  try {
    await sequelize.authenticate();
    console.log('Database connection established successfully.');
    return sequelize;
  } catch (error) {
    console.error('Unable to connect to the database:', error.message);
    throw error;
  }
}

// Create and export the sequelize instance
const sequelize = await initSequelize();

export { sequelize };  // Named export
export default sequelize;  // Also default export for compatibility
