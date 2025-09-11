package com.navia.navia;

import android.content.Context;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import androidx.core.app.ActivityCompat;
import android.Manifest;
import android.content.pm.PackageManager;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.io.FileInputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.io.IOException;
import java.util.List;

import ai.picovoice.eagle.Eagle;
import ai.picovoice.eagle.EagleException;
import ai.picovoice.eagle.EagleProfile;
import ai.picovoice.eagle.EagleProfiler;
import ai.picovoice.eagle.EagleProfilerEnrollResult;
import io.flutter.plugin.common.MethodChannel;

public class VoiceIdService {
    private static final String TAG = "VoiceIdService";
    private static final int SAMPLE_RATE = 16000;
    private static final int CHANNELS = AudioFormat.CHANNEL_IN_MONO;
    private static final int ENCODING = AudioFormat.ENCODING_PCM_16BIT;
    private static final int BUFFER_SIZE = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNELS, ENCODING);
    private static final int FRAME_LENGTH = 512;
    private static final String PROFILE_FILE = "voice_profile.bin";
    private static final int RECORD_DURATION_SECONDS = 7;
    private static final int ENROLLMENT_MULTIPLIER = 4;

    private Eagle eagle;
    private EagleProfiler eagleProfiler;
    private AudioRecord audioRecord;
    private EagleProfile speakerProfile;
    private boolean isRecording = false;

    public VoiceIdService(Context context) {
    }

    public void enrollVoice(Context context, String accessKey, MethodChannel.Result result) {
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            Log.e(TAG, "Microphone permission not granted");
            runOnUiThread(() -> result.error("PERMISSION_ERROR", "Microphone permission not granted", null));
            return;
        }

        if (isProfileEnrolled(context)) {
            Log.d(TAG, "Voice profile already exists. Resetting it.");
            resetEnrollment(context, new MethodChannel.Result() {
                @Override
                public void success(Object o) {
                    Log.d(TAG, "Profile reset success. Starting new enrollment.");
                    startEnrollment(context, result, accessKey);
                }

                @Override
                public void error(String s, String s1, Object o) {
                    Log.e(TAG, "Profile reset failed.");
                    runOnUiThread(() -> result.error(s, s1, o));
                }

                @Override
                public void notImplemented() {
                }
            });
        } else {
            startEnrollment(context, result, accessKey);
        }
    }

    private void startEnrollment(Context context, MethodChannel.Result result, String accessKey) {
        try {
            Log.d(TAG, "Initializing EagleProfiler...");
            eagleProfiler = new EagleProfiler.Builder()
                    .setAccessKey(accessKey)
                    .build(context);
            Log.d(TAG, "EagleProfiler initialized successfully");

            Log.d(TAG, "Starting audio recording...");
            audioRecord = new AudioRecord(MediaRecorder.AudioSource.MIC, SAMPLE_RATE, CHANNELS, ENCODING, BUFFER_SIZE);
            if (audioRecord.getState() != AudioRecord.STATE_INITIALIZED) {
                Log.e(TAG, "Failed to initialize AudioRecord");
                runOnUiThread(() -> result.error("AUDIO_INIT_ERROR", "Failed to initialize audio recording", null));
                stopRecording();
                return;
            }
            audioRecord.startRecording();
            isRecording = true;
            Log.d(TAG, "Audio recording started");

            new Thread(() -> {
                try {
                    int totalSamples = SAMPLE_RATE * RECORD_DURATION_SECONDS;
                    short[] enrollBuffer = new short[totalSamples];
                    int totalSamplesRead = 0;

                    Log.d(TAG, "Recording audio for " + RECORD_DURATION_SECONDS + " seconds...");
                    while (isRecording && totalSamplesRead < totalSamples) {
                        short[] frameBuffer = new short[FRAME_LENGTH];
                        int numRead = audioRecord.read(frameBuffer, 0, frameBuffer.length);
                        if (numRead <= 0) {
                            Log.e(TAG, "Failed to read audio data: " + numRead);
                            runOnUiThread(() -> result.error("AUDIO_READ_ERROR", "Failed to read audio data", null));
                            return;
                        }
                        int samplesToCopy = Math.min(numRead, totalSamples - totalSamplesRead);
                        System.arraycopy(frameBuffer, 0, enrollBuffer, totalSamplesRead, samplesToCopy);
                        totalSamplesRead += samplesToCopy;
                    }
                    Log.d(TAG, "Finished recording audio, total samples read: " + totalSamplesRead);

                    if (totalSamplesRead < totalSamples) {
                        runOnUiThread(() -> result.error("RECORDING_ERROR", "Not enough audio recorded.", null));
                        return;
                    }

                    int multipliedSamples = totalSamples * ENROLLMENT_MULTIPLIER;
                    short[] multipliedEnrollBuffer = new short[multipliedSamples];
                    for (int i = 0; i < ENROLLMENT_MULTIPLIER; i++) {
                        System.arraycopy(enrollBuffer, 0, multipliedEnrollBuffer, i * totalSamples, totalSamples);
                    }
                    Log.d(TAG, "Multiplied audio buffer to " + multipliedSamples + " samples (" + (multipliedSamples / SAMPLE_RATE) + " seconds)");

                    Log.d(TAG, "Starting voice enrollment with multiplied audio...");
                    try {
                        if (eagleProfiler == null) {
                            Log.e(TAG, "EagleProfiler is null before enrollment");
                            runOnUiThread(() -> result.error("ENROLL_ERROR", "EagleProfiler is null", null));
                            return;
                        }

                        EagleProfilerEnrollResult feedbackResult = eagleProfiler.enroll(multipliedEnrollBuffer);
                        Log.d(TAG, "Enrollment percentage after single pass: " + feedbackResult.getPercentage());

                        speakerProfile = eagleProfiler.export();

                        saveProfile(context, speakerProfile);
                        byte[] profileBytes = speakerProfile.getBytes();
                        runOnUiThread(() -> result.success(profileBytes)); // إرسال البيانات الثنائية إلى Dart

                    } catch (EagleException e) {
                        Log.e(TAG, "Enrollment error: " + e.getMessage(), e);
                        runOnUiThread(() -> result.error("ENROLL_ERROR", e.getMessage(), null));
                    }
                } catch (Exception e) {
                    Log.e(TAG, "Unexpected error during enrollment: " + e.getMessage(), e);
                    runOnUiThread(() -> result.error("UNEXPECTED_ERROR", "An unexpected error occurred: " + e.getMessage(), null));
                } finally {
                    Log.d(TAG, "Stopping recording...");
                    stopRecording();
                    Log.d(TAG, "Recording stopped");
                }
            }).start();
        } catch (EagleException e) {
            Log.e(TAG, "Failed to initialize EagleProfiler: " + e.getMessage(), e);
            result.error("ENROLL_INIT_ERROR", e.getMessage(), null);
        } catch (Exception e) {
            Log.e(TAG, "Unexpected error during setup: " + e.getMessage(), e);
            result.error("SETUP_ERROR", "Unexpected error during setup: " + e.getMessage(), null);
        }
    }

    public void resetEnrollment(Context context, MethodChannel.Result result) {
        try {
            File file = new File(context.getFilesDir(), PROFILE_FILE);
            if (file.exists()) {
                file.delete();
            }
            if (speakerProfile != null) {
                speakerProfile = null;
            }
            if (eagle != null) {
                eagle.delete();
                eagle = null;
            }
            Log.d(TAG, "Enrollment reset successfully");
            result.success("Enrollment reset successfully");
        } catch (Exception e) {
            Log.e(TAG, "Failed to reset enrollment: " + e.getMessage(), e);
            result.error("RESET_ERROR", "Failed to reset enrollment: " + e.getMessage(), null);
        }
    }

    public boolean isProfileEnrolled(Context context) {
        File profileFile = new File(context.getFilesDir(), PROFILE_FILE);
        return profileFile.exists();
    }

    public void saveVoiceProfile(Context context, List<Integer> voiceProfileBytes, MethodChannel.Result result) {
        try {
            // Convert List<Integer> to byte[]
            byte[] bytes = new byte[voiceProfileBytes.size()];
            for (int i = 0; i < voiceProfileBytes.size(); i++) {
                bytes[i] = voiceProfileBytes.get(i).byteValue();
            }
            
            // Create EagleProfile from bytes
            EagleProfile profile = new EagleProfile(bytes);
            
            // Save to local file
            saveProfile(context, profile);
            
            // Store in memory for immediate use
            speakerProfile = profile;
            
            Log.d(TAG, "Voice profile saved successfully from login");
            runOnUiThread(() -> result.success(true));
        } catch (Exception e) {
            Log.e(TAG, "Failed to save voice profile: " + e.getMessage(), e);
            runOnUiThread(() -> result.error("SAVE_ERROR", "Failed to save voice profile: " + e.getMessage(), null));
        }
    }

    private void saveProfile(Context context, EagleProfile profile) throws IOException {
        File file = new File(context.getFilesDir(), PROFILE_FILE);
        try (FileOutputStream fos = new FileOutputStream(file)) {
            fos.write(profile.getBytes());
            Log.d(TAG, "Voice profile saved successfully locally");
        }
    }

    private void loadSpeakerProfile(Context context) {
        try {
            File file = new File(context.getFilesDir(), PROFILE_FILE);
            if (file.exists()) {
                FileInputStream fis = new FileInputStream(file);
                byte[] data = new byte[(int) file.length()];
                fis.read(data);
                fis.close();
                speakerProfile = new EagleProfile(data);
                Log.d(TAG, "Speaker profile loaded successfully");
            }
        } catch (Exception e) {
            Log.e(TAG, "Failed to load speaker profile: " + e.getMessage(), e);
        }
    }

    private void stopRecording() {
        isRecording = false;
        if (audioRecord != null) {
            try {
                audioRecord.stop();
                audioRecord.release();
            } catch (Exception e) {
                Log.e(TAG, "Error stopping AudioRecord: " + e.getMessage(), e);
            } finally {
                audioRecord = null;
            }
        }
        if (eagleProfiler != null) {
            try {
                eagleProfiler.delete();
            } catch (Exception e) {
                Log.e(TAG, "Error deleting EagleProfiler: " + e.getMessage(), e);
            } finally {
                eagleProfiler = null;
            }
        }
    }

    public void verifyVoice(Context context, short[] audioBuffer, String accessKey, MethodChannel.Result result) {
        if (speakerProfile == null) {
            Log.e(TAG, "No voice profile enrolled, attempting to load from file...");
            loadSpeakerProfile(context);
            if (speakerProfile == null) {
                Log.e(TAG, "Voice profile is not enrolled or loaded.");
                runOnUiThread(() -> result.error("NO_PROFILE", "No voice profile enrolled", null));
                return;
            }
        }

        if (eagle == null) {
            try {
                eagle = new Eagle.Builder()
                        .setAccessKey(accessKey)
                        .setSpeakerProfiles(new EagleProfile[]{speakerProfile})
                        .build(context);
                Log.d(TAG, "Eagle initialized for verification.");
            } catch (EagleException e) {
                Log.e(TAG, "Failed to initialize Eagle for verification: " + e.getMessage(), e);
                runOnUiThread(() -> result.error("VERIFY_INIT_ERROR", "Failed to initialize Eagle for verification", null));
                return;
            }
        }

        if (audioBuffer == null || audioBuffer.length == 0) {
            Log.e(TAG, "Audio buffer is empty or null");
            runOnUiThread(() -> result.error("INVALID_BUFFER", "Audio buffer is empty or null", null));
            return;
        }

        try {
            int numFrames = audioBuffer.length / FRAME_LENGTH;
            float highestScore = 0;

            for (int i = 0; i < numFrames; i++) {
                short[] frame = new short[FRAME_LENGTH];
                System.arraycopy(audioBuffer, i * FRAME_LENGTH, frame, 0, FRAME_LENGTH);
                float[] scores = eagle.process(frame);
                if (scores.length > 0 && scores[0] > highestScore) {
                    highestScore = scores[0];
                }
            }
            Log.d(TAG, "Voice verification score: " + highestScore);
            if (highestScore > 0.6) {
                Log.d(TAG, "Voice matched");
                runOnUiThread(() -> result.success(true));
            } else {
                Log.d(TAG, "Voice not matched");
                runOnUiThread(() -> result.success(false));
            }
        } catch (EagleException e) {
            Log.e(TAG, "Verification error: " + e.getMessage(), e);
            runOnUiThread(() -> result.error("VERIFY_ERROR", e.getMessage(), null));
        }
    }

    private void runOnUiThread(Runnable runnable) {
        new Handler(Looper.getMainLooper()).post(runnable);
    }
}