import { Clarinet, Tx, Chain, Account, types } from "clarinet-ts";

Clarinet.test({
  name: "Wellness Contract Test Suite",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const user1 = accounts.get("wallet_1")!;
    const user2 = accounts.get("wallet_2")!;

    // Test add-medical-record function
    let block = chain.mineBlock([
      Tx.contractCall("wellness", "add-medical-record", [types.uint(1), types.ascii("Test medical record")], deployer.address),
    ]);
    block.receipts[0].result.expectOk().expectUint(1);

    // Test get-medical-record function
    block = chain.mineBlock([
      Tx.contractCall("wellness", "get-medical-record", [types.uint(1)], deployer.address),
    ]);
    block.receipts[0].result.expectOk().expectTuple()["record"].expectAscii("Test medical record");

    // Test submit-claim function
    block = chain.mineBlock([
      Tx.contractCall("wellness", "submit-claim", [types.uint(500)], user1.address),
    ]);
    block.receipts[0].result.expectOk().expectUint(375); // 75% of 500

    // Test add-bill function
    block = chain.mineBlock([
      Tx.contractCall("wellness", "add-bill", [types.ascii("Test Service"), types.uint(100)], deployer.address),
    ]);
    block.receipts[0].result.expectOk().expectAscii("Test Service");

    // Test pay-bill function
    block = chain.mineBlock([
      Tx.contractCall("wellness", "pay-bill", [types.ascii("Test Service"), types.uint(100)], user1.address),
    ]);
    block.receipts[0].result.expectOk().expectBool(true);

    // Test authorize-user function
    block = chain.mineBlock([
      Tx.contractCall("wellness", "authorize-user", [types.principal(user1.address), types.ascii("doctor")], deployer.address),
    ]);
    block.receipts[0].result.expectOk();

    // Test is-user-authorized function
    block = chain.mineBlock([
      Tx.contractCall("wellness", "is-user-authorized", [types.principal(user1.address), types.ascii("doctor")], deployer.address),
    ]);
    block.receipts[0].result.expectBool(true);

    // Test add-patient-visit function
    block = chain.mineBlock([
      Tx.contractCall("wellness", "add-patient-visit", [types.uint(1), types.ascii("Regular checkup")], user1.address),
    ]);
    block.receipts[0].result.expectOk();

    // Test get-patient-visits function
    block = chain.mineBlock([
      Tx.contractCall("wellness", "get-patient-visits", [types.uint(1)], deployer.address),
    ]);
    let visits = block.receipts[0].result.expectOk().expectList();
    visits.length.expectInt(1);
    visits[0].expectTuple()["diagnosis"].expectAscii("Regular checkup");

    // Test add-emergency-contact function
    block = chain.mineBlock([
      Tx.contractCall("wellness", "add-emergency-contact", [types.uint(1), types.ascii("John Doe"), types.ascii("123-456-7890")], deployer.address),
    ]);
    block.receipts[0].result.expectOk();

    // Test get-emergency-contact function
    block = chain.mineBlock([
      Tx.contractCall("wellness", "get-emergency-contact", [types.uint(1)], deployer.address),
    ]);
    let contact = block.receipts[0].result.expectSome().expectTuple();
    contact["name"].expectAscii("John Doe");
    contact["phone"].expectAscii("123-456-7890");

    console.log("All tests passed!");
  },
});