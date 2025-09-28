import { Router } from "express";

import { registerSaleHandler } from "../handlers/saleHandler";

const saleRoutes = Router();

saleRoutes.post("/", registerSaleHandler);

export default saleRoutes;
