import { Router } from "express";

import { settleCommerceHandler } from "../handlers/commerceHandler";

const commerceRoutes = Router();

commerceRoutes.post("/settle", settleCommerceHandler);

export default commerceRoutes;