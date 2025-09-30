import { Router } from "express";

import { registerSaleHandler } from "../handlers/saleHandler";

const saleRoutes = Router();

/* This line of code is setting up a POST route for the "/register" endpoint on the saleRoutes router.
When a POST request is made to this endpoint, the registerSaleHandler function will be called to
handle the request. This allows clients to register a new sale by sending data to this endpoint. */
saleRoutes.post("/register", registerSaleHandler);

export default saleRoutes;
