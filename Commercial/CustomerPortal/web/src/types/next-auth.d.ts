import type { DefaultSession } from "next-auth";

declare module "next-auth" {
  interface Session {
    user: DefaultSession["user"] & {
      role?: "admin" | "customer" | "support" | string;
    };
  }

  interface User {
    role?: "admin" | "customer" | "support" | string;
  }
}

declare module "next-auth/jwt" {
  interface JWT {
    role?: "admin" | "customer" | "support" | string;
  }
}
