import { Router } from "express";

import { settleCommerceHandler } from "../handlers/commerceHandler";

const commerceRoutes = Router();

/* This line of code is setting up a POST route on the `commerceRoutes` router for the endpoint
"/settle". When a POST request is made to this endpoint, the `settleCommerceHandler` function will
be called to handle the request. */
commerceRoutes.post("/settle", settleCommerceHandler)

export default commerceRoutes