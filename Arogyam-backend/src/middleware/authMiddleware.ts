import { Request, Response, NextFunction } from 'express';
import { auth } from '../lib/firebase';
import prisma from '../lib/prisma';
import { Role } from '@prisma/client';

export interface AuthRequest extends Request {
  user?: {
    uid: string;
    email?: string;
    role: Role;
    dbUserId: string;
  };
}

export const protect = (roles: Role[] = []) => {
  return async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ message: 'Unauthorized' });
      }

      const token = authHeader.split(' ')[1];
      const decodedToken = await auth.verifyIdToken(token);

      const dbUser = await prisma.user.findUnique({
        where: { firebaseUid: decodedToken.uid },
      });

      if (!dbUser) {
        return res.status(404).json({ message: 'User not found in local database' });
      }

      if (roles.length > 0 && !roles.includes(dbUser.role)) {
        return res.status(403).json({ message: 'Forbidden: Insufficient permissions' });
      }

      req.user = {
        uid: decodedToken.uid,
        email: decodedToken.email,
        role: dbUser.role,
        dbUserId: dbUser.id,
      };

      next();
    } catch (error) {
      console.error('Auth Error:', error);
      res.status(401).json({ message: 'Invalid token' });
    }
  };
};
