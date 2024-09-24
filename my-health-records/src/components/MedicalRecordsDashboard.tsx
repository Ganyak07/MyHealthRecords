import React, { useState } from 'react';
import { useConnect } from '@stacks/connect-react';
import { callReadOnlyFunction, callContractFunction } from '@stacks/transactions';
import { StacksMainnet } from '@stacks/network';

const MedicalRecordsDashboard = () => {
  const { doContractCall } = useConnect();
  const [patientId, setPatientId] = useState('');
  const [medicalRecord, setMedicalRecord] = useState('');
  const [fetchedRecord, setFetchedRecord] = useState('');
  const [claimAmount, setClaimAmount] = useState('');
  const [billService, setBillService] = useState('');
  const [billAmount, setBillAmount] = useState('');

  const handleGetRecord = async () => {
    try {
      const result = await callReadOnlyFunction({
        contractAddress: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
        contractName: 'wellness',
        functionName: 'get-medical-record',
        functionArgs: [patientId],
        network: new StacksMainnet(),
      });
      setFetchedRecord(result.value);
    } catch (error) {
      console.error('Error fetching record:', error);
    }
  };

  const handleAddRecord = async () => {
    await doContractCall({
      contractAddress: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
      contractName: 'wellness',
      functionName: 'add-medical-record',
      functionArgs: [patientId, medicalRecord],
      onFinish: (data) => {
        console.log('Transaction ID:', data.txId);
      },
      onCancel: () => {
        console.log('Transaction cancelled');
      },
    });
  };

  const handleSubmitClaim = async () => {
    await doContractCall({
      contractAddress: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
      contractName: 'wellness',
      functionName: 'submit-claim',
      functionArgs: [claimAmount],
      onFinish: (data) => {
        console.log('Claim submitted. Transaction ID:', data.txId);
      },
      onCancel: () => {
        console.log('Claim submission cancelled');
      },
    });
  };

  const handleAddBill = async () => {
    await doContractCall({
      contractAddress: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
      contractName: 'wellness',
      functionName: 'add-bill',
      functionArgs: [billService, billAmount],
      onFinish: (data) => {
        console.log('Bill added. Transaction ID:', data.txId);
      },
      onCancel: () => {
        console.log('Bill addition cancelled');
      },
    });
  };

  return (
    <div className="p-4 max-w-4xl mx-auto">
      <h1 className="text-3xl font-bold mb-6">Medical Records Dashboard</h1>
      
      <div className="bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4">
        <h2 className="text-xl font-semibold mb-4">Medical Records</h2>
        <div className="mb-4">
          <label className="block text-gray-700 text-sm font-bold mb-2" htmlFor="patientId">
            Patient ID
          </label>
          <input
            className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
            id="patientId"
            type="text"
            placeholder="Enter patient ID"
            value={patientId}
            onChange={(e) => setPatientId(e.target.value)}
          />
        </div>
        <div className="mb-4">
          <label className="block text-gray-700 text-sm font-bold mb-2" htmlFor="medicalRecord">
            Medical Record
          </label>
          <textarea
            className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
            id="medicalRecord"
            placeholder="Enter medical record"
            value={medicalRecord}
            onChange={(e) => setMedicalRecord(e.target.value)}
          />
        </div>
        <div className="flex items-center justify-between">
          <button
            className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
            type="button"
            onClick={handleAddRecord}
          >
            Add Record
          </button>
          <button
            className="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
            type="button"
            onClick={handleGetRecord}
          >
            Get Record
          </button>
        </div>
        {fetchedRecord && (
          <div className="mt-4">
            <h3 className="text-lg font-semibold">Fetched Record:</h3>
            <p className="mt-2 text-gray-700">{fetchedRecord}</p>
          </div>
        )}
      </div>

      <div className="bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4">
        <h2 className="text-xl font-semibold mb-4">Insurance Claims</h2>
        <div className="mb-4">
          <label className="block text-gray-700 text-sm font-bold mb-2" htmlFor="claimAmount">
            Claim Amount
          </label>
          <input
            className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
            id="claimAmount"
            type="text"
            placeholder="Enter claim amount"
            value={claimAmount}
            onChange={(e) => setClaimAmount(e.target.value)}
          />
        </div>
        <button
          className="bg-purple-500 hover:bg-purple-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
          type="button"
          onClick={handleSubmitClaim}
        >
          Submit Claim
        </button>
      </div>

      <div className="bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4">
        <h2 className="text-xl font-semibold mb-4">Medical Bills</h2>
        <div className="mb-4">
          <label className="block text-gray-700 text-sm font-bold mb-2" htmlFor="billService">
            Service Name
          </label>
          <input
            className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
            id="billService"
            type="text"
            placeholder="Enter service name"
            value={billService}
            onChange={(e) => setBillService(e.target.value)}
          />
        </div>
        <div className="mb-4">
          <label className="block text-gray-700 text-sm font-bold mb-2" htmlFor="billAmount">
            Bill Amount
          </label>
          <input
            className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
            id="billAmount"
            type="text"
            placeholder="Enter bill amount"
            value={billAmount}
            onChange={(e) => setBillAmount(e.target.value)}
          />
        </div>
        <button
          className="bg-yellow-500 hover:bg-yellow-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
          type="button"
          onClick={handleAddBill}
        >
          Add Bill
        </button>
      </div>
    </div>
  );
};

export default MedicalRecordsDashboard;