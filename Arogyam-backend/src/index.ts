import express from 'express';
import http from 'http';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import { setupSocket } from './socket';
import authRoutes from './routes/auth';
import patientRoutes from './routes/patient';
import doctorRoutes from './routes/doctor';
import receptionRoutes from './routes/reception';
import pharmacyRoutes from './routes/pharmacy';
import adminRoutes from './routes/admin';
import consentSessionRoutes from './routes/consentSession';
import webhookRoutes from './routes/webhook';

dotenv.config();

const app = express();
const server = http.createServer(app);
const port = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());

// Socket Setup
const io = setupSocket(server);

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/patients', patientRoutes);
app.use('/api/doctors', doctorRoutes);
app.use('/api/reception', receptionRoutes);
app.use('/reception', receptionRoutes);
app.use('/api/pharmacy', pharmacyRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/consent-sessions', consentSessionRoutes);
app.use('/consent-sessions', consentSessionRoutes);
app.use('/api/webhooks', webhookRoutes);
app.use('/webhooks', webhookRoutes);

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

server.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});

export { io };
