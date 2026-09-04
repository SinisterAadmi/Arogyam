import { Request, Response } from 'express';
import { AuthService } from '../services/authService';

export const login = async (req: Request, res: Response) => {
  try {
    const { idToken } = req.body;
    if (!idToken) {
      return res.status(400).json({ message: 'ID Token is required' });
    }

    const result = await AuthService.login(idToken);
    res.json(result);
  } catch (error: any) {
    console.error('Login Error:', error);
    res.status(401).json({ message: 'Authentication failed', error: error.message });
  }
};

export const signup = async (req: Request, res: Response) => {
  try {
    const { idToken, name, dob, gender } = req.body;
    if (!idToken || !name) {
      return res.status(400).json({ message: 'ID Token and Name are required' });
    }

    const user = await AuthService.registerPatient(idToken, { name, dob, gender });
    res.status(201).json({ status: 'success', user });
  } catch (error: any) {
    console.error('Signup Error:', error);
    res.status(400).json({ message: 'Registration failed', error: error.message });
  }
};
