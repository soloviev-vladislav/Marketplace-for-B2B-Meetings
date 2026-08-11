import { z } from "zod";

export const loginSchema = z.object({
  email: z.string().trim().email("Введите корректный email"),
  password: z.string().min(8, "Пароль должен содержать минимум 8 символов"),
});

export const signupSchema = loginSchema.extend({
  displayName: z.string().trim().min(2, "Укажите имя").max(80),
  role: z.enum(["SDR", "BUSINESS"]),
});
