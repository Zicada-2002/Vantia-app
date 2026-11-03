import { initializeApp } from "firebase-admin/app";
import { setGlobalOptions } from "firebase-functions/v2";

initializeApp();
setGlobalOptions({ region: "southamerica-east1", maxInstances: 10 });

export { createBusiness, generateInvite, redeemInvite } from "./business.js";
export { notifyOwnerOnPayment, revokeInvite, setMemberActive } from "./collaborators.js";
export { closeCashSession, reopenCashSession } from "./cash.js";
export { onPaymentWrite } from "./stats.js";
export { decrementStockOnSale } from "./products.js";
