# 🏷️ Gestión de Claim Topics

## Descripción

Los **Claim Topics** definen qué tipos de verificaciones (claims) son necesarios para que los holders puedan poseer y transferir tokens. Cada topic es un ID numérico que representa un tipo de verificación específica.

## 📋 Topics Comunes

| ID | Nombre | Descripción |
|----|--------|-------------|
| 1 | KYC | Know Your Customer - Verificación de identidad |
| 2 | AML | Anti-Money Laundering - Verificación anti-lavado |
| 3 | Accredited Investor | Inversor acreditado |
| 4 | Country Verification | Verificación de país permitido |
| 5 | Age Verification | Verificación de edad mínima |

## 🔧 Funciones del Contrato

El contrato `ClaimTopicsRegistry` incluye:

```solidity
// Añadir topic
function addClaimTopic(uint256 _claimTopic) external onlyOwner

// ✅ Eliminar topic
function removeClaimTopic(uint256 _claimTopic) external onlyOwner

// Ver todos los topics
function getClaimTopics() external view returns (uint256[] memory)

// Verificar si existe
function claimTopicExists(uint256 _claimTopic) external view returns (bool)

// Contar topics
function getClaimTopicsCount() external view returns (uint256)
```

---

## 🖥️ Método 1: Usar el Script de Shell

### Instalación

El script ya está creado y es ejecutable:
```bash
sc/scripts/manage-claim-topics.sh
```

### Comandos Disponibles

#### 1. Listar Topics

```bash
./scripts/manage-claim-topics.sh list <REGISTRY_ADDRESS>
```

**Ejemplo:**
```bash
cd sc
./scripts/manage-claim-topics.sh list 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
```

#### 2. Añadir Topic

```bash
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
./scripts/manage-claim-topics.sh add <REGISTRY_ADDRESS> <TOPIC_ID>
```

**Ejemplo - Añadir KYC:**
```bash
cd sc
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
./scripts/manage-claim-topics.sh add 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 1
```

#### 3. ✅ Eliminar Topic

```bash
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
./scripts/manage-claim-topics.sh remove <REGISTRY_ADDRESS> <TOPIC_ID>
```

**Ejemplo - Eliminar AML:**
```bash
cd sc
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
./scripts/manage-claim-topics.sh remove 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 2
```

**Nota:** El script pedirá confirmación antes de eliminar.

#### 4. Verificar si Existe

```bash
./scripts/manage-claim-topics.sh exists <REGISTRY_ADDRESS> <TOPIC_ID>
```

**Ejemplo:**
```bash
cd sc
./scripts/manage-claim-topics.sh exists 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 1
```

### Variables de Entorno

```bash
# RPC URL (opcional, default: http://localhost:8545)
export RPC_URL=http://localhost:8545

# Private Key (requerida para add/remove)
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

---

## 💻 Método 2: Usar Cast Directamente

### Listar Topics

```bash
cast call 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 \
  "getClaimTopics()" \
  --rpc-url http://localhost:8545
```

### Añadir Topic

```bash
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

cast send 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 \
  "addClaimTopic(uint256)" \
  1 \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY
```

### ✅ Eliminar Topic

```bash
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

cast send 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 \
  "removeClaimTopic(uint256)" \
  2 \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY
```

### Verificar si Existe

```bash
cast call 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 \
  "claimTopicExists(uint256)" \
  1 \
  --rpc-url http://localhost:8545
```

### Contar Topics

```bash
cast call 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 \
  "getClaimTopicsCount()" \
  --rpc-url http://localhost:8545
```

---

## 🌐 Método 3: Interfaz Web (React/TypeScript)

Se ha creado un componente completo de ejemplo en:
```
CLAIM_TOPICS_UI_EXAMPLE.tsx
```

### Características del Componente

✅ **Lista de topics** con nombres descriptivos  
✅ **Botón de eliminar** al lado de cada topic  
✅ **Selector** para añadir nuevos topics  
✅ **Confirmación** antes de eliminar  
✅ **Verificación de permisos** (solo owner puede modificar)  
✅ **Mensajes de error/éxito**  
✅ **Estilos incluidos**  

### Uso del Componente

```typescript
import ClaimTopicsManager from './ClaimTopicsManager';
import { ethers } from 'ethers';

function App() {
  const [provider, setProvider] = useState<ethers.providers.Web3Provider>();
  
  useEffect(() => {
    if (window.ethereum) {
      const web3Provider = new ethers.providers.Web3Provider(window.ethereum);
      setProvider(web3Provider);
    }
  }, []);

  return (
    <ClaimTopicsManager 
      registryAddress="0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"
      provider={provider}
    />
  );
}
```

### Funciones Clave

```typescript
// ✅ Función para eliminar topic con confirmación
const removeTopic = async (topicId: number) => {
  const confirmed = window.confirm(
    `⚠️ Are you sure you want to remove this topic?`
  );
  
  if (!confirmed) return;
  
  const contract = new ethers.Contract(
    registryAddress,
    CLAIM_TOPICS_REGISTRY_ABI,
    signer
  );
  
  const tx = await contract.removeClaimTopic(topicId);
  await tx.wait();
};
```

### Vista del Componente

```
┌─────────────────────────────────────────────────┐
│  Claim Topics Registry                          │
│  Registry: 0x9fE4...                           │
├─────────────────────────────────────────────────┤
│  Add New Topic                                  │
│  [Select topic ▼] [Add Topic]                  │
├─────────────────────────────────────────────────┤
│  Active Topics (3)                              │
│  ┌───────────────────────────────────────────┐ │
│  │ 1  KYC (Know Your Customer)    [🗑️ Remove]│ │
│  │ 2  AML (Anti-Money Laundering) [🗑️ Remove]│ │
│  │ 3  Accredited Investor         [🗑️ Remove]│ │
│  └───────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

---

## 📝 Ejemplo Completo: Workflow

### Escenario: Configurar Registry para un Token

```bash
cd sc
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
REGISTRY=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0

# 1. Ver estado actual
./scripts/manage-claim-topics.sh list $REGISTRY

# 2. Añadir KYC y AML (básicos)
./scripts/manage-claim-topics.sh add $REGISTRY 1  # KYC
./scripts/manage-claim-topics.sh add $REGISTRY 2  # AML

# 3. Añadir Accredited Investor
./scripts/manage-claim-topics.sh add $REGISTRY 3

# 4. Ver topics configurados
./scripts/manage-claim-topics.sh list $REGISTRY

# 5. Si decidimos que no necesitamos AML, lo eliminamos
./scripts/manage-claim-topics.sh remove $REGISTRY 2

# 6. Verificar resultado final
./scripts/manage-claim-topics.sh list $REGISTRY
```

---

## ⚠️ Consideraciones Importantes

### Seguridad

1. **Solo el Owner** puede añadir/eliminar topics
2. **Confirmación requerida** antes de eliminar
3. **Validación** de que el topic existe antes de eliminar

### Impacto en Compliance

⚠️ **ADVERTENCIA:** Eliminar un topic puede afectar:
- Holders actuales que no tengan otros topics requeridos
- Validación de transfers
- Compliance requirements del token

**Recomendación:** Antes de eliminar un topic:
1. Verificar cuántos holders dependen de ese topic
2. Comunicar el cambio a los holders
3. Dar tiempo para obtener otros claims necesarios
4. Considerar usar un periodo de transición

### Buenas Prácticas

1. **Documentar cambios:** Mantener registro de qué topics se añaden/eliminan y por qué
2. **Testing primero:** Probar en testnet antes de producción
3. **Notificar holders:** Informar antes de hacer cambios
4. **Backup de estado:** Guardar lista de topics antes de modificar

---

## 🔍 Troubleshooting

### Error: "Only owner can call this function"

```bash
# Verificar owner del registry
cast call $REGISTRY "owner()" --rpc-url http://localhost:8545

# Verificar tu dirección
cast wallet address --private-key $PRIVATE_KEY
```

**Solución:** Asegúrate de usar la private key del owner.

### Error: "Claim topic does not exist"

```bash
# Verificar topics existentes
./scripts/manage-claim-topics.sh list $REGISTRY
```

**Solución:** Verifica que el topic existe antes de intentar eliminarlo.

### Error: "Claim topic already exists"

```bash
# Verificar si existe
./scripts/manage-claim-topics.sh exists $REGISTRY 1
```

**Solución:** El topic ya está añadido, no es necesario añadirlo de nuevo.

---

## 📚 Recursos

- **Contrato:** `sc/src/ClaimTopicsRegistry.sol`
- **Interface:** `sc/src/IClaimTopicsRegistry.sol`
- **Script:** `sc/scripts/manage-claim-topics.sh`
- **Componente UI:** `CLAIM_TOPICS_UI_EXAMPLE.tsx`
- **Tests:** `sc/test/ClaimTopicsRegistry.t.sol`

---

## 🎯 Resumen Rápido

### Comandos Esenciales

```bash
# Listar
./scripts/manage-claim-topics.sh list $REGISTRY

# Añadir
./scripts/manage-claim-topics.sh add $REGISTRY <ID>

# ✅ Eliminar
./scripts/manage-claim-topics.sh remove $REGISTRY <ID>

# Verificar
./scripts/manage-claim-topics.sh exists $REGISTRY <ID>
```

### Topics Comunes

- `1` = KYC
- `2` = AML
- `3` = Accredited Investor
- `4` = Country Verification
- `5` = Age Verification

---

**Última actualización:** 2025-11-11

