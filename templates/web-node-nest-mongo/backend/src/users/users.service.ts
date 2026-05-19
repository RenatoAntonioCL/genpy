import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User, UserDocument } from './user.schema';

@Injectable()
export class UsersService {
  constructor(@InjectModel(User.name) private userModel: Model<UserDocument>) {}

  // Añadimos el método que el controlador está pidiendo
  async findAll(): Promise<User[]> {
    return this.userModel.find().exec();
  }

  async create(email: string) {
    const newUser = new this.userModel({ email });
    return await newUser.save();
  }
}