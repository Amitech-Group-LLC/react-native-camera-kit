package com.rncamerakit

import android.annotation.SuppressLint
import android.util.Size
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

class QRCodeAnalyzer (
    private val onQRCodesDetected: (qrCodes: List<Barcode>, imageSize: Size) -> Unit,
    private val scanThrottleDelay: Long = 0L
    val qrTypes: Array<String>?
) : ImageAnalysis.Analyzer {
    // Time in milliseconds of the last time we dispatched detected barcodes
    private var lastBarcodeDetectedTime: Long = 0L
    @SuppressLint("UnsafeExperimentalUsageError")
    @ExperimentalGetImage
    override fun analyze(image: ImageProxy) {
        val mediaImage = image.image ?: return

        val inputImage = InputImage.fromMediaImage(mediaImage, image.imageInfo.rotationDegrees)

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
                // Throttle callback invocations based on scanThrottleDelay (ms)
                val now = System.currentTimeMillis()
                if (scanThrottleDelay > 0 && (now - lastBarcodeDetectedTime) < scanThrottleDelay) {
                    return@addOnSuccessListener
                }

                val strBarcodes = mutableListOf<Barcode>()
                barcodes.forEach { barcode ->
                    strBarcodes.add(barcode ?: return@forEach)
                }

                if (strBarcodes.isNotEmpty()) {
                    lastBarcodeDetectedTime = now
                    onQRCodesDetected(strBarcodes, Size(image.width, image.height))
                }
            }
            .addOnCompleteListener {
                image.close()
            }
    }
}
