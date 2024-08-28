import { Clarinet, Tx, Chain, Account, types } from "clarinet-ts";

// Test suite for the Wellness smart contract
Clarinet.test({
  name: "Test add-medical-record function",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer")!;
    let user = accounts.get("wallet_1")!;

    // Initialize the test environment
    let block = chain.mineBlock([
      Tx.contractCall("wellness", "initialize-test-env", [], deployer.address),
    ]);
    block.receipts[0].result.expectOk();

    // Test the add-medical-record function
    block = chain.mineBlock([
      Tx.contractCall("wellness", "add-medical-record", [types.uint(2), types.ascii("New medical record")], user.address),
    ]);
    block.receipts[0].result.expectOk().expectUint(2);
  },
});

Clarinet.test({
  name: "Test get-medical-record function",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer")!;

    // Initialize the test environment
    let block = chain.mineBlock([
      Tx.contractCall("wellness", "initialize-test-env", [], deployer.address),
    ]);
    block.receipts[0].result.expectOk();

    // Test the get-medical-record function
    block = chain.mineBlock([
      Tx.contractCall("wellness", "get-medical-record", [types.uint(1)], deployer.address),
    ]);
    block.receipts[0].result.expectOk().expectAscii("Test medical record");
  },
});

Clarinet.test({
  name: "Test add-admin function",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer")!;
    let user = accounts.get("wallet_2")!;

    // Initialize the test environment
    let block = chain.mineBlock([
      Tx.contractCall("wellness", "initialize-test-env", [], deployer.address),
    ]);
    block.receipts[0].result.expectOk();

    // Test the add-admin function
    block = chain.mineBlock([
      Tx.contractCall("wellness", "add-admin", [types.principal(user.address)], deployer.address),
    ]);
    block.receipts[0].result.expectOk();

    // Verify the admin was added
    block = chain.mineBlock([
      Tx.contractCall("wellness", "is-admin", [types.principal(user.address)], deployer.address),
    ]);
    block.receipts[0].result.expectBool(true);
  },
});

Clarinet.test({
  name: "Test get-policy-details function",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer")!;

    // Initialize the test environment
    let block = chain.mineBlock([
      Tx.contractCall("wellness", "initialize-test-env", [], deployer.address),
    ]);
    block.receipts[0].result.expectOk();

    // Test the get-policy-details function
    block = chain.mineBlock([
      Tx.contractCall("wellness", "get-policy-details", [types.ascii("TEST-POLICY-1")], deployer.address),
    ]);
    let policy = block.receipts[0].result.expectOk().expectTuple();
    policy["coverage"].expectUint(10000);
    policy["premium"].expectUint(100);
    policy["active"].expectBool(true);
  },
});

Clarinet.test({
  name: "Test batch-pay-bills function",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer")!;

    // Initialize the test environment
    let block = chain.mineBlock([
      Tx.contractCall("wellness", "initialize-test-env", [], deployer.address),
    ]);
    block.receipts[0].result.expectOk();

    // Test the batch-pay-bills function
    block = chain.mineBlock([
      Tx.contractCall("wellness", "batch-pay-bills", [types.list([types.ascii("TEST-SERVICE-1")])], deployer.address),
    ]);
    block.receipts[0].result.expectOk();

    // Verify that the bill has been paid
    block = chain.mineBlock([
      Tx.contractCall("wellness", "get-bill", [types.ascii("TEST-SERVICE-1")], deployer.address),
    ]);
    let bill = block.receipts[0].result.expectOk().expectTuple();
    bill["paid"].expectBool(true);
  },
});
