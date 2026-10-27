import { CognitoJwtVerifier } from "aws-jwt-verify";
import {
  FetchError,
  JwkInvalidKtyError,
  JwkInvalidUseError,
  JwkValidationError,
  JwksNotAvailableInCacheError,
  JwksValidationError,
  JwtInvalidClaimError,
  JwtInvalidSignatureAlgorithmError,
  JwtInvalidSignatureError,
  JwtParseError,
  JwtWithoutValidKidError,
  KidNotFoundInJwksError,
  ParameterValidationError,
  WaitPeriodNotYetEndedJwkError,
} from "aws-jwt-verify/error";
import type { FastifyInstance, FastifyReply, FastifyRequest } from "fastify";

export interface CognitoAccessTokenVerifierOptions {
  readonly userPoolId: string;
  readonly clientId: string;
}

export interface CognitoAccessTokenVerifier {
  verify(token: string): Promise<{ readonly sub: string }>;
}

export type CognitoAccessTokenPreHandler = (
  request: FastifyRequest,
  reply: FastifyReply,
) => Promise<void>;

declare module "fastify" {
  interface FastifyRequest {
    consumerSub: string | null;
  }
}

export function decorateConsumerSub(server: FastifyInstance): void {
  server.decorateRequest("consumerSub", null);
}

export function createCognitoAccessTokenVerifier(
  options: CognitoAccessTokenVerifierOptions,
): CognitoAccessTokenVerifier {
  if (options === null || typeof options !== "object") {
    throw new TypeError("Cognito verifier options are required.");
  }
  if (typeof options.clientId !== "string" || options.clientId.trim().length === 0) {
    throw new TypeError("Cognito clientId must be a non-empty string.");
  }

  const verifier = CognitoJwtVerifier.create({
    userPoolId: options.userPoolId,
    tokenUse: "access",
    clientId: options.clientId,
  });

  return {
    async verify(token) {
      const claims = await verifier.verify(token);
      if (typeof claims.sub !== "string" || claims.sub.trim().length === 0) {
        throw new Error("Verified Cognito access token is missing sub.");
      }

      return { sub: claims.sub };
    },
  };
}

export function createCognitoAccessTokenPreHandler(
  verifier: CognitoAccessTokenVerifier,
): CognitoAccessTokenPreHandler {
  return async (request, reply) => {
    const token = parseBearerToken(request.headers.authorization);
    if (token === undefined) {
      sendUnauthorized(reply);
      return;
    }

    try {
      const identity = await verifier.verify(token);
      if (typeof identity.sub !== "string" || identity.sub.trim().length === 0) {
        sendUnauthorized(reply);
        return;
      }

      request.consumerSub = identity.sub;
    } catch (error: unknown) {
      const failure = classifyVerifierFailure(error);
      if (failure === "invalid_token") {
        sendUnauthorized(reply);
        return;
      }
      if (failure === "jwks_unavailable") {
        request.log.error(
          { event: "cognito_jwks_unavailable" },
          "Cognito JWKS unavailable",
        );
        reply.code(503).send({ status: "unavailable" });
        return;
      }

      request.log.error(
        { event: "cognito_verification_failed" },
        "Cognito verification failed",
      );
      reply.code(500).send({ status: "error" });
    }
  };
}

function classifyVerifierFailure(
  error: unknown,
): "invalid_token" | "jwks_unavailable" | "unexpected" {
  if (
    error instanceof FetchError ||
    error instanceof JwkInvalidKtyError ||
    error instanceof JwkInvalidUseError ||
    error instanceof JwkValidationError ||
    error instanceof JwksNotAvailableInCacheError ||
    error instanceof JwksValidationError ||
    error instanceof WaitPeriodNotYetEndedJwkError
  ) {
    return "jwks_unavailable";
  }

  if (
    error instanceof JwtInvalidClaimError ||
    error instanceof JwtInvalidSignatureAlgorithmError ||
    error instanceof JwtInvalidSignatureError ||
    error instanceof JwtParseError ||
    error instanceof JwtWithoutValidKidError ||
    error instanceof KidNotFoundInJwksError ||
    error instanceof ParameterValidationError
  ) {
    return "invalid_token";
  }

  return "unexpected";
}

function sendUnauthorized(reply: FastifyReply): void {
  reply.header("WWW-Authenticate", "Bearer").code(401).send({ status: "unauthorized" });
}

function parseBearerToken(authorization: string | string[] | undefined): string | undefined {
  if (typeof authorization !== "string") return undefined;

  const match = /^Bearer[ \t]+([^\s,]+)$/i.exec(authorization);
  return match?.[1];
}
