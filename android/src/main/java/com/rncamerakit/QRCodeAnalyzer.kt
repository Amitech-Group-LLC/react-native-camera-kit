package com.rncamerakit

import android.annotation.SuppressLint
import androidx.camera.core.ExperimentalGetImage
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage

val initBarcodeTypes = listOf(Barcode.FORMAT_EAN_8,
    Barcode.FORMAT_EAN_13,
    Barcode.FORMAT_UPC_E,
    Barcode.FORMAT_UNKNOWN,
    Barcode.FORMAT_ALL_FORMATS,
    Barcode.FORMAT_CODE_128,
    Barcode.FORMAT_CODE_39,
    Barcode.FORMAT_CODE_93,
    Barcode.FORMAT_CODABAR,
    Barcode.FORMAT_DATA_MATRIX,
    Barcode.FORMAT_ITF,
    Barcode.FORMAT_QR_CODE,
    Barcode.FORMAT_UPC_A,
    Barcode.FORMAT_PDF417,
    Barcode.FORMAT_AZTEC
)

val typesMap = mapOf(
    "ean8" to Barcode.FORMAT_EAN_8,
    "ean13" to Barcode.FORMAT_EAN_13,
    "upce" to Barcode.FORMAT_UPC_E,
    "unknown" to Barcode.FORMAT_UNKNOWN,
    "all" to Barcode.FORMAT_ALL_FORMATS,
    "code128" to Barcode.FORMAT_CODE_128,
    "code39" to Barcode.FORMAT_CODE_39,
    "code93" to Barcode.FORMAT_CODE_93,
    "codabar" to Barcode.FORMAT_CODABAR,
    "matrix" to Barcode.FORMAT_DATA_MATRIX,
    "itf" to Barcode.FORMAT_ITF,
    "qr" to Barcode.FORMAT_QR_CODE,
    "upca" to Barcode.FORMAT_UPC_A,
    "pdf417" to Barcode.FORMAT_PDF417,
    "aztec" to Barcode.FORMAT_AZTEC
)

class QRCodeAnalyzer(
    private val onQRCodesDetected: (qrCodes: List<String>) -> Unit,
    val qrTypes: Array<String>?
) : ImageAnalysis.Analyzer {
    @SuppressLint("UnsafeExperimentalUsageError")
    @ExperimentalGetImage
    override fun analyze(image: ImageProxy) {

        val inputImage = InputImage.fromMediaImage(image.image!!, image.imageInfo.rotationDegrees)
        var barcodeFormats: List<Int?>
        if(qrTypes != null){
            barcodeFormats = qrTypes.map { typesMap[it] }
        } else {
            barcodeFormats = initBarcodeTypes
        }
        val nonNullableQRList: List<Int> = barcodeFormats.filterNotNull()

        val remainQRCodes = nonNullableQRList.drop(1).toIntArray()

        val options = BarcodeScannerOptions.Builder()
            .setBarcodeFormats(
                nonNullableQRList[0],
                *remainQRCodes
            )
            .build();

        val scanner = BarcodeScanning.getClient(options)
        scanner.process(inputImage)
            .addOnSuccessListener { barcodes ->
                val strBarcodes = mutableListOf<String>()
                barcodes.forEach { barcode ->
                    strBarcodes.add(barcode.rawValue ?: return@forEach)
                }
                onQRCodesDetected(strBarcodes)
            }
            .addOnCompleteListener{
                image.close()
            }
    }
}
