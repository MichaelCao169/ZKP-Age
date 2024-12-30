const express = require('express');
const snarkjs = require('snarkjs');
const path = require('path');

const app = express();
app.use(express.json());
app.use(express.static('public'));

app.post('/api/verify', async (req, res) => {
    try {
        const { age, threshold } = req.body;
        console.log('Request received:', { age, threshold });

        const input = {
            age: parseInt(age),
            threshold: parseInt(threshold),
            nonce: Math.floor(Math.random() * 1000000)
        };
        console.log('Processing input:', input);

        const { proof, publicSignals } = await snarkjs.groth16.fullProve(
            input,
            path.join(__dirname, '../build/ageProof_js/ageProof.wasm'),
            path.join(__dirname, '../build/zkey/ageProof_final.zkey')
        );
        console.log('Proof generated:', { proof, publicSignals });

        const vKey = require('../build/zkey/verification_key.json');
        const verified = await snarkjs.groth16.verify(vKey, publicSignals, proof);
        console.log('Verification result:', verified);

        const isAgeValid = publicSignals[0] === "1";
        const response = { 
            success: true, 
            verified, 
            proof,
            isAgeValid,
            message: isAgeValid ? 
                "Age verification passed! Age is above threshold." : 
                "Age verification failed! Age is below threshold."
        };
        
        console.log('Sending response:', response);
        res.json(response);
    } catch (error) {
        console.error('Error in /api/verify:', error);
        res.status(500).json({ 
            success: false, 
            error: error.message 
        });
    }
});

const PORT = 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));