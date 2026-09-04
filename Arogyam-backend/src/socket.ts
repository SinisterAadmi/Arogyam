import { Server, Socket } from 'socket.io';
import { Server as HttpServer } from 'http';
import { auth } from './lib/firebase';
import prisma from './lib/prisma';

let ioInstance: Server | null = null;

export const getIO = (): Server | null => ioInstance;

export const setupSocket = (server: HttpServer) => {
  const io = new Server(server, {
    cors: {
      origin: '*',
    },
  });
  ioInstance = io;

  io.on('connection', (socket: Socket) => {
    console.log('Client connected:', socket.id);

    // Post-connect authentication
    socket.on('join', async (data: { token: string }) => {
      try {
        const decodedToken = await auth.verifyIdToken(data.token);
        const userIdentifier = decodedToken.email || decodedToken.phone_number || decodedToken.uid;
        console.log('Socket authenticated for user:', userIdentifier);

        // Join room based on Firebase UID
        socket.join(decodedToken.uid);
        socket.join(`user:${decodedToken.uid}`);

        const joinedRooms: string[] = [decodedToken.uid, `user:${decodedToken.uid}`];
        let userRole = 'unknown';
        let receptionClinicId: string | null = null;

        // Also join patient/reception rooms if user has profile
        try {
          const dbUser = await prisma.user.findUnique({
            where: { firebaseUid: decodedToken.uid },
            include: { patient: true, reception: true },
          });

          if (dbUser) {
            userRole = dbUser.role;
          }

          if (dbUser?.patient) {
            socket.join(dbUser.patient.id);
            socket.join(`patient:${dbUser.patient.id}`);
            joinedRooms.push(dbUser.patient.id, `patient:${dbUser.patient.id}`);
          }

          if (dbUser?.reception) {
            receptionClinicId = dbUser.reception.clinicId;
            socket.join(dbUser.reception.clinicId);
            socket.join(`clinic:${dbUser.reception.clinicId}`);
            socket.join(`reception:${dbUser.reception.clinicId}`);
            joinedRooms.push(
              dbUser.reception.clinicId,
              `clinic:${dbUser.reception.clinicId}`,
              `reception:${dbUser.reception.clinicId}`
            );
          }
        } catch (dbErr) {
          console.error('[DIAGNOSTIC] Error querying dbUser for socket join:', dbErr);
        }

        console.log('[DIAGNOSTIC] [Socket Connect & Join]', {
          socketId: socket.id,
          userIdentifier,
          role: userRole,
          receptionClinicId,
          allJoinedRooms: joinedRooms,
        });

        socket.emit('authenticated', { status: 'success' });
      } catch (error) {
        console.error('Socket authentication failed:', error);
        socket.emit('error', { message: 'Authentication failed' });
        socket.disconnect();
      }
    });

    socket.on('subscribe_appointment', (data: { appointmentId: string }) => {
      if (data?.appointmentId) {
        socket.join(data.appointmentId);
        socket.join(`appointment:${data.appointmentId}`);
        socket.emit('subscribed', { appointmentId: data.appointmentId });
      }
    });

    socket.on('disconnect', () => {
      console.log('Client disconnected:', socket.id);
    });
  });

  return io;
};
