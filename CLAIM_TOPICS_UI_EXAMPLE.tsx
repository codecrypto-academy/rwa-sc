// Ejemplo de componente React/TypeScript para gestionar Claim Topics
// con botones para añadir y ELIMINAR topics

import { useState, useEffect } from 'react';
import { ethers } from 'ethers';

// ABI del ClaimTopicsRegistry
const CLAIM_TOPICS_REGISTRY_ABI = [
  "function getClaimTopics() external view returns (uint256[])",
  "function addClaimTopic(uint256 _claimTopic) external",
  "function removeClaimTopic(uint256 _claimTopic) external",
  "function claimTopicExists(uint256 _claimTopic) external view returns (bool)",
  "function getClaimTopicsCount() external view returns (uint256)",
  "function owner() external view returns (address)"
];

// Nombres de los topics comunes
const TOPIC_NAMES: { [key: number]: string } = {
  1: 'KYC (Know Your Customer)',
  2: 'AML (Anti-Money Laundering)',
  3: 'Accredited Investor',
  4: 'Country Verification',
  5: 'Age Verification',
};

interface ClaimTopicsManagerProps {
  registryAddress: string;
  provider: ethers.providers.Web3Provider;
}

export default function ClaimTopicsManager({ 
  registryAddress, 
  provider 
}: ClaimTopicsManagerProps) {
  const [topics, setTopics] = useState<number[]>([]);
  const [loading, setLoading] = useState(false);
  const [isOwner, setIsOwner] = useState(false);
  const [newTopic, setNewTopic] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  // Cargar topics al montar el componente
  useEffect(() => {
    loadTopics();
    checkOwnership();
  }, [registryAddress]);

  const loadTopics = async () => {
    try {
      setLoading(true);
      const contract = new ethers.Contract(
        registryAddress,
        CLAIM_TOPICS_REGISTRY_ABI,
        provider
      );

      const topicsArray = await contract.getClaimTopics();
      setTopics(topicsArray.map((t: ethers.BigNumber) => t.toNumber()));
      setError(null);
    } catch (err: any) {
      setError(`Error loading topics: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const checkOwnership = async () => {
    try {
      const signer = provider.getSigner();
      const address = await signer.getAddress();
      
      const contract = new ethers.Contract(
        registryAddress,
        CLAIM_TOPICS_REGISTRY_ABI,
        provider
      );

      const owner = await contract.owner();
      setIsOwner(owner.toLowerCase() === address.toLowerCase());
    } catch (err) {
      console.error('Error checking ownership:', err);
    }
  };

  const addTopic = async () => {
    if (!newTopic) return;
    
    try {
      setLoading(true);
      setError(null);
      setSuccess(null);

      const signer = provider.getSigner();
      const contract = new ethers.Contract(
        registryAddress,
        CLAIM_TOPICS_REGISTRY_ABI,
        signer
      );

      const topicId = parseInt(newTopic);
      
      // Verificar si ya existe
      const exists = await contract.claimTopicExists(topicId);
      if (exists) {
        setError('This topic already exists!');
        return;
      }

      const tx = await contract.addClaimTopic(topicId);
      await tx.wait();

      setSuccess(`Topic ${topicId} added successfully!`);
      setNewTopic('');
      await loadTopics();
    } catch (err: any) {
      setError(`Error adding topic: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  // 🔴 FUNCIÓN PARA ELIMINAR TOPIC
  const removeTopic = async (topicId: number) => {
    // Confirmación antes de eliminar
    const topicName = TOPIC_NAMES[topicId] || `Topic ${topicId}`;
    const confirmed = window.confirm(
      `⚠️ Are you sure you want to remove "${topicName}"?\n\n` +
      `This may affect token compliance requirements.`
    );

    if (!confirmed) return;

    try {
      setLoading(true);
      setError(null);
      setSuccess(null);

      const signer = provider.getSigner();
      const contract = new ethers.Contract(
        registryAddress,
        CLAIM_TOPICS_REGISTRY_ABI,
        signer
      );

      const tx = await contract.removeClaimTopic(topicId);
      await tx.wait();

      setSuccess(`Topic ${topicId} removed successfully!`);
      await loadTopics();
    } catch (err: any) {
      setError(`Error removing topic: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="claim-topics-manager">
      <h2>Claim Topics Registry</h2>
      <p className="registry-address">
        Registry: <code>{registryAddress}</code>
      </p>

      {/* Mensajes de error/éxito */}
      {error && (
        <div className="alert alert-error">
          ❌ {error}
        </div>
      )}
      {success && (
        <div className="alert alert-success">
          ✅ {success}
        </div>
      )}

      {/* Solo mostrar controles si es owner */}
      {isOwner && (
        <div className="add-topic-section">
          <h3>Add New Topic</h3>
          <div className="input-group">
            <select 
              value={newTopic} 
              onChange={(e) => setNewTopic(e.target.value)}
              disabled={loading}
            >
              <option value="">Select a topic...</option>
              <option value="1">1 - KYC (Know Your Customer)</option>
              <option value="2">2 - AML (Anti-Money Laundering)</option>
              <option value="3">3 - Accredited Investor</option>
              <option value="4">4 - Country Verification</option>
              <option value="5">5 - Age Verification</option>
            </select>
            <button 
              onClick={addTopic} 
              disabled={loading || !newTopic}
              className="btn btn-primary"
            >
              {loading ? 'Adding...' : 'Add Topic'}
            </button>
          </div>
        </div>
      )}

      {/* Lista de topics con botón de eliminar */}
      <div className="topics-list">
        <h3>Active Topics ({topics.length})</h3>
        
        {loading && <p>Loading topics...</p>}
        
        {!loading && topics.length === 0 && (
          <p className="no-topics">No claim topics configured yet.</p>
        )}

        {!loading && topics.length > 0 && (
          <ul className="topics-items">
            {topics.map((topicId) => (
              <li key={topicId} className="topic-item">
                <div className="topic-info">
                  <span className="topic-id">{topicId}</span>
                  <span className="topic-name">
                    {TOPIC_NAMES[topicId] || 'Custom Topic'}
                  </span>
                </div>
                
                {/* 🔴 BOTÓN DE ELIMINAR */}
                {isOwner && (
                  <button
                    onClick={() => removeTopic(topicId)}
                    disabled={loading}
                    className="btn btn-danger btn-small"
                    title="Remove this topic"
                  >
                    🗑️ Remove
                  </button>
                )}
              </li>
            ))}
          </ul>
        )}
      </div>

      {!isOwner && (
        <div className="info-box">
          ℹ️ You are not the owner of this registry. You can only view topics.
        </div>
      )}

      <style jsx>{`
        .claim-topics-manager {
          max-width: 800px;
          margin: 0 auto;
          padding: 20px;
        }

        .registry-address {
          background: #f5f5f5;
          padding: 10px;
          border-radius: 4px;
          margin-bottom: 20px;
        }

        .registry-address code {
          font-family: monospace;
          font-size: 0.9em;
        }

        .alert {
          padding: 12px;
          border-radius: 4px;
          margin-bottom: 20px;
        }

        .alert-error {
          background: #fee;
          border: 1px solid #fcc;
          color: #c33;
        }

        .alert-success {
          background: #efe;
          border: 1px solid #cfc;
          color: #3c3;
        }

        .add-topic-section {
          background: #f9f9f9;
          padding: 20px;
          border-radius: 8px;
          margin-bottom: 30px;
        }

        .input-group {
          display: flex;
          gap: 10px;
        }

        .input-group select {
          flex: 1;
          padding: 10px;
          border: 1px solid #ddd;
          border-radius: 4px;
          font-size: 14px;
        }

        .btn {
          padding: 10px 20px;
          border: none;
          border-radius: 4px;
          cursor: pointer;
          font-size: 14px;
          font-weight: 500;
          transition: all 0.2s;
        }

        .btn:disabled {
          opacity: 0.5;
          cursor: not-allowed;
        }

        .btn-primary {
          background: #007bff;
          color: white;
        }

        .btn-primary:hover:not(:disabled) {
          background: #0056b3;
        }

        .btn-danger {
          background: #dc3545;
          color: white;
        }

        .btn-danger:hover:not(:disabled) {
          background: #c82333;
        }

        .btn-small {
          padding: 6px 12px;
          font-size: 12px;
        }

        .topics-list {
          background: white;
          border: 1px solid #ddd;
          border-radius: 8px;
          padding: 20px;
        }

        .topics-items {
          list-style: none;
          padding: 0;
          margin: 0;
        }

        .topic-item {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 12px;
          border-bottom: 1px solid #eee;
        }

        .topic-item:last-child {
          border-bottom: none;
        }

        .topic-info {
          display: flex;
          gap: 12px;
          align-items: center;
        }

        .topic-id {
          display: inline-block;
          width: 30px;
          height: 30px;
          line-height: 30px;
          text-align: center;
          background: #007bff;
          color: white;
          border-radius: 50%;
          font-weight: bold;
          font-size: 14px;
        }

        .topic-name {
          font-size: 14px;
          color: #333;
        }

        .no-topics {
          text-align: center;
          color: #999;
          padding: 20px;
        }

        .info-box {
          background: #e7f3ff;
          border: 1px solid #b3d9ff;
          padding: 12px;
          border-radius: 4px;
          margin-top: 20px;
          color: #004085;
        }
      `}</style>
    </div>
  );
}

/* 
 * EJEMPLO DE USO:
 * 
 * import ClaimTopicsManager from './ClaimTopicsManager';
 * 
 * function App() {
 *   const [provider, setProvider] = useState<ethers.providers.Web3Provider>();
 *   
 *   useEffect(() => {
 *     if (window.ethereum) {
 *       const web3Provider = new ethers.providers.Web3Provider(window.ethereum);
 *       setProvider(web3Provider);
 *     }
 *   }, []);
 * 
 *   return (
 *     <ClaimTopicsManager 
 *       registryAddress="0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"
 *       provider={provider}
 *     />
 *   );
 * }
 */

