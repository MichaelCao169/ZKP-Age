#!/bin/bash

# Set up directories
BUILD_DIR="./build"
INPUTS_DIR="$BUILD_DIR/inputs"
AGEPROOF_JS_DIR="$BUILD_DIR/ageProof_js"
PROOFS_DIR="$BUILD_DIR/proofs"
ZKEY_DIR="$BUILD_DIR/zkey"
POT12_DIR="$BUILD_DIR/pot12"
circom circuits/ageProof.circom --r1cs --wasm --sym -o build/
# Create necessary directories if they don't exist
mkdir -p "$INPUTS_DIR" "$PROOFS_DIR" "$ZKEY_DIR" "$POT12_DIR"

# Create input.json if it doesn't exist
if [ ! -f "$INPUTS_DIR/input.json" ]; then
  echo "Creating input.json..."
  cat <<EOL > "$INPUTS_DIR/input.json"
{
  "age": 25,
  "threshold": 18,
  "nonce": 123456
}
EOL
fi

# Generate witness if it doesn't exist
if [ ! -f "$AGEPROOF_JS_DIR/witness.wtns" ]; then
  echo "Generating witness..."
  node "$AGEPROOF_JS_DIR/generate_witness.js" "$AGEPROOF_JS_DIR/ageProof.wasm" "$INPUTS_DIR/input.json" "$AGEPROOF_JS_DIR/witness.wtns"
fi

# Perform trusted setup and create zkey files if they don't exist
if [ ! -f "$ZKEY_DIR/ageProof_final.zkey" ]; then
  echo "Performing trusted setup..."
  snarkjs powersoftau new bn128 12 "$POT12_DIR/pot12_0000.ptau" -v
  snarkjs powersoftau contribute "$POT12_DIR/pot12_0000.ptau" "$POT12_DIR/pot12_0001.ptau" --name="First contribution" -v
  snarkjs powersoftau prepare phase2 "$POT12_DIR/pot12_0001.ptau" "$POT12_DIR/pot12_final.ptau" -v
  snarkjs groth16 setup "$BUILD_DIR/ageProof.r1cs" "$POT12_DIR/pot12_final.ptau" "$ZKEY_DIR/ageProof_0000.zkey"
  snarkjs zkey contribute "$ZKEY_DIR/ageProof_0000.zkey" "$ZKEY_DIR/ageProof_final.zkey" --name="My Contribution" -v
  snarkjs zkey export verificationkey "$ZKEY_DIR/ageProof_final.zkey" "$ZKEY_DIR/verification_key.json"
fi

# Generate proof and public.json
echo "Generating proof..."
snarkjs groth16 prove "$ZKEY_DIR/ageProof_final.zkey" "$AGEPROOF_JS_DIR/witness.wtns" "$PROOFS_DIR/proof.json" "$PROOFS_DIR/public.json"

# Verify proof
echo "Verifying proof..."
snarkjs groth16 verify "$ZKEY_DIR/verification_key.json" "$PROOFS_DIR/public.json" "$PROOFS_DIR/proof.json"

echo "Process completed."
