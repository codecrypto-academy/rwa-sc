# 🚀 Quick Start: Eliminar Claim Topics

## ✅ Funcionalidad Implementada

La función `removeClaimTopic()` **ya está implementada** en el contrato `ClaimTopicsRegistry.sol`.

```solidity
function removeClaimTopic(uint256 _claimTopic) external onlyOwner {
    require(claimTopicExists(_claimTopic), "Claim topic does not exist");
    
    // Encontrar y eliminar el topic
    for (uint256 i = 0; i < claimTopics.length; i++) {
        if (claimTopics[i] == _claimTopic) {
            claimTopics[i] = claimTopics[claimTopics.length - 1];
            claimTopics.pop();
            break;
        }
    }
    
    emit ClaimTopicRemoved(_claimTopic);
}
```

---

## 📦 Archivos Creados

### 1. Script de Shell: `manage-claim-topics.sh`
**Ubicación:** `sc/scripts/manage-claim-topics.sh`

✅ Lista topics  
✅ Añade topics  
✅ **Elimina topics** (con confirmación)  
✅ Verifica si existen  

### 2. Componente React: `CLAIM_TOPICS_UI_EXAMPLE.tsx`
**Ubicación:** `CLAIM_TOPICS_UI_EXAMPLE.tsx`

✅ Interfaz completa con tabla de topics  
✅ **Botón "Remove"** al lado de cada topic  
✅ Confirmación antes de eliminar  
✅ Validación de permisos (owner)  

### 3. Documentación: `CLAIM_TOPICS_MANAGEMENT.md`
**Ubicación:** `CLAIM_TOPICS_MANAGEMENT.md`

✅ Guía completa de uso  
✅ Ejemplos de todos los métodos  
✅ Troubleshooting  

---

## 🖥️ Uso del Script

### Instalación
```bash
cd sc
chmod +x scripts/manage-claim-topics.sh  # Ya ejecutable
```

### Listar Topics
```bash
./scripts/manage-claim-topics.sh list <REGISTRY_ADDRESS>
```

### ✅ Eliminar Topic
```bash
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
./scripts/manage-claim-topics.sh remove <REGISTRY_ADDRESS> <TOPIC_ID>
```

**Ejemplo:**
```bash
# Eliminar el topic AML (ID: 2)
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
./scripts/manage-claim-topics.sh remove 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 2
```

**Output esperado:**
```
========================================
   CLAIM TOPICS MANAGEMENT
========================================

Removing claim topic: 2 (AML (Anti-Money Laundering))
  Registry: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0

⚠️  WARNING: This will remove the claim topic!
  This may affect token compliance requirements.

  Continue? (yes/no): yes

✓ Claim topic removed successfully

  Transaction: 0x1234567890abcdef...

========================================
```

---

## 💻 Uso con Cast (Directo)

### Eliminar Topic
```bash
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

cast send 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 \
  "removeClaimTopic(uint256)" \
  2 \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY
```

### Verificar Eliminación
```bash
# Ver todos los topics
cast call 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 \
  "getClaimTopics()" \
  --rpc-url http://localhost:8545

# Verificar que el topic no existe
cast call 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 \
  "claimTopicExists(uint256)" \
  2 \
  --rpc-url http://localhost:8545
# Debe retornar: 0x0000...0000 (false)
```

---

## 🌐 Integración en UI Web

### Componente React con Botón de Eliminar

```typescript
// El botón ya está implementado en CLAIM_TOPICS_UI_EXAMPLE.tsx

const removeTopic = async (topicId: number) => {
  // Confirmación
  const confirmed = window.confirm(
    `⚠️ Are you sure you want to remove this topic?`
  );
  if (!confirmed) return;

  // Eliminar
  const contract = new ethers.Contract(
    registryAddress,
    CLAIM_TOPICS_REGISTRY_ABI,
    signer
  );
  
  const tx = await contract.removeClaimTopic(topicId);
  await tx.wait();
  
  // Recargar lista
  await loadTopics();
};

// Botón en la UI
<button
  onClick={() => removeTopic(topicId)}
  className="btn btn-danger"
>
  🗑️ Remove
</button>
```

### Vista del Botón

```
┌────────────────────────────────────────────┐
│ Active Topics (3)                          │
├────────────────────────────────────────────┤
│ ① KYC (Know Your Customer)    [🗑️ Remove] │
│ ② AML (Anti-Money Laundering) [🗑️ Remove] │
│ ③ Accredited Investor         [🗑️ Remove] │
└────────────────────────────────────────────┘
```

---

## 📋 IDs de Topics Comunes

| ID | Nombre | Cuándo Usar |
|----|--------|-------------|
| 1 | KYC | Siempre (identificación básica) |
| 2 | AML | Para cumplimiento regulatorio |
| 3 | Accredited Investor | Securities privados |
| 4 | Country Verification | Restricciones geográficas |
| 5 | Age Verification | Restricción de edad |

---

## 🔄 Workflow Completo

### Escenario: Eliminar un Topic No Necesario

```bash
# 1. Ver topics actuales
./scripts/manage-claim-topics.sh list $REGISTRY

# Output:
# ✓ Found 3 claim topics:
#   - KYC
#   - AML
#   - Accredited Investor

# 2. Decidimos que no necesitamos "Accredited Investor"
export PRIVATE_KEY=0xac0974...
./scripts/manage-claim-topics.sh remove $REGISTRY 3

# 3. Confirmar en el prompt
# Continue? (yes/no): yes

# 4. Verificar que se eliminó
./scripts/manage-claim-topics.sh list $REGISTRY

# Output:
# ✓ Found 2 claim topics:
#   - KYC
#   - AML
```

---

## ⚠️ Advertencias Importantes

### Antes de Eliminar un Topic:

1. ✅ **Verificar impacto:** ¿Cuántos holders tienen solo ese topic?
2. ✅ **Comunicar:** Notificar a los holders del cambio
3. ✅ **Alternativas:** Asegurar que holders tengan otros topics válidos
4. ✅ **Testing:** Probar primero en testnet

### El Script Incluye:

- ✅ Confirmación obligatoria (`yes/no`)
- ✅ Advertencia visible
- ✅ Validación de existencia
- ✅ Solo owner puede ejecutar

---

## 🎯 Ejemplo Práctico

### Setup Inicial

```bash
cd sc
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
REGISTRY=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
```

### Añadir Topics

```bash
# Añadir KYC, AML y Accredited
./scripts/manage-claim-topics.sh add $REGISTRY 1  # KYC
./scripts/manage-claim-topics.sh add $REGISTRY 2  # AML
./scripts/manage-claim-topics.sh add $REGISTRY 3  # Accredited
```

### Ver Estado

```bash
./scripts/manage-claim-topics.sh list $REGISTRY
```

### Eliminar Topic

```bash
# Decidimos que no necesitamos "Accredited Investor"
./scripts/manage-claim-topics.sh remove $REGISTRY 3
# Confirmar con: yes
```

### Verificar

```bash
# Verificar que se eliminó
./scripts/manage-claim-topics.sh exists $REGISTRY 3
# Debe mostrar: ✗ Topic does not exist
```

---

## 🔍 Troubleshooting

### Error: "Only owner can call this function"

**Causa:** No eres el owner del registry

**Solución:**
```bash
# Verificar owner
cast call $REGISTRY "owner()" --rpc-url http://localhost:8545

# Usar la private key correcta
export PRIVATE_KEY=<owner_private_key>
```

### Error: "Claim topic does not exist"

**Causa:** El topic ya fue eliminado o nunca existió

**Solución:**
```bash
# Ver topics existentes
./scripts/manage-claim-topics.sh list $REGISTRY
```

### Script no ejecuta

**Solución:**
```bash
chmod +x sc/scripts/manage-claim-topics.sh
```

---

## 📚 Referencias

- **Contrato:** `sc/src/ClaimTopicsRegistry.sol` (líneas 41-53)
- **Script:** `sc/scripts/manage-claim-topics.sh`
- **UI Component:** `CLAIM_TOPICS_UI_EXAMPLE.tsx`
- **Guía Completa:** `CLAIM_TOPICS_MANAGEMENT.md`

---

## ✅ Resumen

### Lo que tienes disponible:

1. ✅ **Función en contrato:** `removeClaimTopic()` implementada
2. ✅ **Script de shell:** Con confirmación y validaciones
3. ✅ **Componente React:** Con botón de eliminar
4. ✅ **Documentación:** Completa con ejemplos

### Comandos esenciales:

```bash
# Eliminar topic
./scripts/manage-claim-topics.sh remove $REGISTRY <TOPIC_ID>

# O con cast
cast send $REGISTRY "removeClaimTopic(uint256)" <TOPIC_ID> \
  --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY
```

---

**¡Todo listo para usar!** 🚀

