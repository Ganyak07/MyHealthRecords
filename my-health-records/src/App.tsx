import React from 'react';
import { Connect } from '@stacks/connect-react';
import MedicalRecordsDashboard from './components/MedicalRecordsDashboard';

function App() {
  return (
    <Connect authOptions={{
      appDetails: {
        name: 'My Health Records',
        icon: window.location.origin + '/logo.svg',
      },
      redirectTo: '/',
      onFinish: () => {
        window.location.reload();
      },
    }}>
      <div className="App">
        <MedicalRecordsDashboard />
      </div>
    </Connect>
  );
}

export default App;