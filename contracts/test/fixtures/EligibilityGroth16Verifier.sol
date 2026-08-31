// SPDX-License-Identifier: GPL-3.0
/*
    Copyright 2021 0KIMS association.

    This file is generated with [snarkJS](https://github.com/iden3/snarkjs).

    snarkJS is a free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    snarkJS is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
    License for more details.

    You should have received a copy of the GNU General Public License
    along with snarkJS. If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.7.0 <0.9.0;

contract Groth16Verifier {
    // Scalar field size
    uint256 constant r =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant q =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 constant alphax =
        4478172643983265360669545754002467796821651059184341994149274137312260418054;
    uint256 constant alphay =
        19632574650501227370070209231145128334026037385071391654271074121620718642067;
    uint256 constant betax1 =
        11460228018856011959775410027185743500155861378307270124607869175463611944040;
    uint256 constant betax2 =
        6595186478360415691259771428322598179982773809916262428581779151954825416166;
    uint256 constant betay1 =
        123015034455549783845450875978490777425518861944073672942357050282495710340;
    uint256 constant betay2 =
        7589641159446793494451373660965973455038427469411253546184457493580620532212;
    uint256 constant gammax1 =
        11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 =
        10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 =
        4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 =
        8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 =
        2245054222390994800970522939760356150313081360809765979320243754145157967514;
    uint256 constant deltax2 =
        18316678196554975240313783686184208976226188044301265960982066719295307624523;
    uint256 constant deltay1 =
        7006997016408557367316223325406781180252516283763646066612016529792121071203;
    uint256 constant deltay2 =
        4982312125061706063910547785570819423940063938651843547627675808027909995291;

    uint256 constant IC0x =
        13228951364577303680420224632476765732363931379940664785451873477888093444601;
    uint256 constant IC0y =
        21886936644661390452125998735377187471507518202325332848151634484983688820074;

    uint256 constant IC1x =
        15509429676806062381341263324766693035729814519232794847121638095953287606476;
    uint256 constant IC1y =
        11895981648039624284587255223494412486102812424242683837572826440516021011559;

    uint256 constant IC2x =
        19297037626438337833027324171456564722306156627044482335429402332171994895526;
    uint256 constant IC2y =
        12706885432695342125599999433229395669836415254201440965349685812343765502555;

    uint256 constant IC3x =
        8671217075358763211442593043187263494510068439484174636256217092064115821231;
    uint256 constant IC3y =
        21713796073291595584697723290844467661659662367891022472325485614759887642830;

    uint256 constant IC4x =
        6518211386076039061221768330286656635002686945749558242708895052420203798394;
    uint256 constant IC4y =
        10911044507808112350417444792482835427496400576038239658352618249126940569902;

    uint256 constant IC5x =
        20682455678898503937341797916642747058563572804100165324601457384878616158316;
    uint256 constant IC5y =
        12750816333522724939015120325574328851731913511596377747740420895229922365915;

    uint256 constant IC6x =
        19755988632702975493470460756456133987887317259453710745407618725480718951363;
    uint256 constant IC6y =
        4888637858028666018750409657603803481139471941526088697394139465354423187792;

    uint256 constant IC7x =
        6920330211873426981519035902340245704610887251960266122579599987824322436872;
    uint256 constant IC7y =
        8406949878509972007675544960348686866284693561546405243210051828939914167744;

    uint256 constant IC8x =
        8081000635618011948901516364703816457729869951793772858746901188289780441746;
    uint256 constant IC8y =
        5119950927052242173982101956912334056555782414230574530221527418002903325052;

    uint256 constant IC9x =
        12340615895507922338998615817936088595070615738621509100361389869367642638686;
    uint256 constant IC9y =
        5854481420862796667126355362034938613084299279344429538486666575357092906153;

    uint256 constant IC10x =
        5176849409101638687670631117343552092804551691745682542125133122158494461880;
    uint256 constant IC10y =
        8450678390843084347513143965657315573266889814948437015453592239883919027490;

    uint256 constant IC11x =
        17408583704912458681460841577222995227113762617725541432870460598136671792769;
    uint256 constant IC11y =
        904773806111807777107525935823936555629073379619092105700149580899041150390;

    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(
        uint256[2] calldata _pA,
        uint256[2][2] calldata _pB,
        uint256[2] calldata _pC,
        uint256[11] calldata _pubSignals
    ) public view returns (bool) {
        assembly {
            function checkField(v) {
                if iszero(lt(v, r)) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            // G1 function to multiply a G1 value(x,y) to value in an address
            function g1_mulAccC(pR, x, y, s) {
                let success
                let mIn := mload(0x40)
                mstore(mIn, x)
                mstore(add(mIn, 32), y)
                mstore(add(mIn, 64), s)

                success := staticcall(sub(gas(), 2000), 7, mIn, 96, mIn, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }

                mstore(add(mIn, 64), mload(pR))
                mstore(add(mIn, 96), mload(add(pR, 32)))

                success := staticcall(sub(gas(), 2000), 6, mIn, 128, pR, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            function checkPairing(pA, pB, pC, pubSignals, pMem) -> isOk {
                let _pPairing := add(pMem, pPairing)
                let _pVk := add(pMem, pVk)

                mstore(_pVk, IC0x)
                mstore(add(_pVk, 32), IC0y)

                // Compute the linear combination vk_x

                g1_mulAccC(_pVk, IC1x, IC1y, calldataload(add(pubSignals, 0)))

                g1_mulAccC(_pVk, IC2x, IC2y, calldataload(add(pubSignals, 32)))

                g1_mulAccC(_pVk, IC3x, IC3y, calldataload(add(pubSignals, 64)))

                g1_mulAccC(_pVk, IC4x, IC4y, calldataload(add(pubSignals, 96)))

                g1_mulAccC(_pVk, IC5x, IC5y, calldataload(add(pubSignals, 128)))

                g1_mulAccC(_pVk, IC6x, IC6y, calldataload(add(pubSignals, 160)))

                g1_mulAccC(_pVk, IC7x, IC7y, calldataload(add(pubSignals, 192)))

                g1_mulAccC(_pVk, IC8x, IC8y, calldataload(add(pubSignals, 224)))

                g1_mulAccC(_pVk, IC9x, IC9y, calldataload(add(pubSignals, 256)))

                g1_mulAccC(_pVk, IC10x, IC10y, calldataload(add(pubSignals, 288)))

                g1_mulAccC(_pVk, IC11x, IC11y, calldataload(add(pubSignals, 320)))

                // -A
                mstore(_pPairing, calldataload(pA))
                mstore(add(_pPairing, 32), mod(sub(q, calldataload(add(pA, 32))), q))

                // B
                mstore(add(_pPairing, 64), calldataload(pB))
                mstore(add(_pPairing, 96), calldataload(add(pB, 32)))
                mstore(add(_pPairing, 128), calldataload(add(pB, 64)))
                mstore(add(_pPairing, 160), calldataload(add(pB, 96)))

                // alpha1
                mstore(add(_pPairing, 192), alphax)
                mstore(add(_pPairing, 224), alphay)

                // beta2
                mstore(add(_pPairing, 256), betax1)
                mstore(add(_pPairing, 288), betax2)
                mstore(add(_pPairing, 320), betay1)
                mstore(add(_pPairing, 352), betay2)

                // vk_x
                mstore(add(_pPairing, 384), mload(add(pMem, pVk)))
                mstore(add(_pPairing, 416), mload(add(pMem, add(pVk, 32))))

                // gamma2
                mstore(add(_pPairing, 448), gammax1)
                mstore(add(_pPairing, 480), gammax2)
                mstore(add(_pPairing, 512), gammay1)
                mstore(add(_pPairing, 544), gammay2)

                // C
                mstore(add(_pPairing, 576), calldataload(pC))
                mstore(add(_pPairing, 608), calldataload(add(pC, 32)))

                // delta2
                mstore(add(_pPairing, 640), deltax1)
                mstore(add(_pPairing, 672), deltax2)
                mstore(add(_pPairing, 704), deltay1)
                mstore(add(_pPairing, 736), deltay2)

                let success := staticcall(sub(gas(), 2000), 8, _pPairing, 768, _pPairing, 0x20)

                isOk := and(success, mload(_pPairing))
            }

            let pMem := mload(0x40)
            mstore(0x40, add(pMem, pLastMem))

            // Validate that all evaluations âˆˆ F

            checkField(calldataload(add(_pubSignals, 0)))

            checkField(calldataload(add(_pubSignals, 32)))

            checkField(calldataload(add(_pubSignals, 64)))

            checkField(calldataload(add(_pubSignals, 96)))

            checkField(calldataload(add(_pubSignals, 128)))

            checkField(calldataload(add(_pubSignals, 160)))

            checkField(calldataload(add(_pubSignals, 192)))

            checkField(calldataload(add(_pubSignals, 224)))

            checkField(calldataload(add(_pubSignals, 256)))

            checkField(calldataload(add(_pubSignals, 288)))

            checkField(calldataload(add(_pubSignals, 320)))

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
            return(0, 0x20)
        }
    }
}

