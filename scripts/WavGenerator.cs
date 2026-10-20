using System;
using System.IO;

public class WavGenerator
{
    public static void Main()
    {
        string outDir = @"assets\audio";
        Directory.CreateDirectory(outDir);

        GenerateTap(Path.Combine(outDir, "tap.wav"));
        GeneratePickup(Path.Combine(outDir, "pickup.wav"));
        GenerateDrop(Path.Combine(outDir, "drop.wav"));
        GenerateSnap(Path.Combine(outDir, "snap.wav"));
        GenerateHint(Path.Combine(outDir, "hint.wav"));
        GenerateStar(Path.Combine(outDir, "star.wav"));
        GenerateLevelStart(Path.Combine(outDir, "level_start.wav"));
        GenerateVictory(Path.Combine(outDir, "victory.wav"));
        GenerateBgm(Path.Combine(outDir, "bgm_loop.wav"));

        Console.WriteLine("All audio files generated successfully.");
    }

    static void WriteWav(string path, short[] samples, int sampleRate)
    {
        using (FileStream fs = new FileStream(path, FileMode.Create))
        using (BinaryWriter bw = new BinaryWriter(fs))
        {
            int byteRate = sampleRate * 2;
            int dataChunkSize = samples.Length * 2;

            bw.Write(new char[] { 'R', 'I', 'F', 'F' });
            bw.Write(36 + dataChunkSize);
            bw.Write(new char[] { 'W', 'A', 'V', 'E' });
            bw.Write(new char[] { 'f', 'm', 't', ' ' });
            bw.Write(16); // subchunk 1 size (16 for PCM)
            bw.Write((short)1); // PCM
            bw.Write((short)1); // mono
            bw.Write(sampleRate);
            bw.Write(byteRate);
            bw.Write((short)2); // block align
            bw.Write((short)16); // bits per sample
            bw.Write(new char[] { 'd', 'a', 't', 'a' });
            bw.Write(dataChunkSize);

            for (int i = 0; i < samples.Length; i++)
            {
                bw.Write(samples[i]);
            }
        }
    }

    static void GenerateTap(string path)
    {
        int sr = 44100;
        int len = (int)(sr * 0.08); // 80ms
        short[] s = new short[len];
        for (int i = 0; i < len; i++)
        {
            double t = (double)i / sr;
            double env = Math.Exp(-t * 50);
            double val = Math.Sin(2 * Math.PI * 800 * t) * env;
            s[i] = (short)(val * 16000);
        }
        WriteWav(path, s, sr);
    }

    static void GeneratePickup(string path)
    {
        int sr = 44100;
        int len = (int)(sr * 0.12);
        short[] s = new short[len];
        for (int i = 0; i < len; i++)
        {
            double t = (double)i / sr;
            double freq = 350 + (t / 0.12) * 250;
            double env = Math.Sin(Math.PI * (t / 0.12));
            double val = Math.Sin(2 * Math.PI * freq * t) * env;
            s[i] = (short)(val * 18000);
        }
        WriteWav(path, s, sr);
    }

    static void GenerateDrop(string path)
    {
        int sr = 44100;
        int len = (int)(sr * 0.10);
        short[] s = new short[len];
        for (int i = 0; i < len; i++)
        {
            double t = (double)i / sr;
            double freq = 450 - (t / 0.10) * 200;
            double env = Math.Exp(-t * 40);
            double val = Math.Sin(2 * Math.PI * freq * t) * env;
            s[i] = (short)(val * 18000);
        }
        WriteWav(path, s, sr);
    }

    static void GenerateSnap(string path)
    {
        int sr = 44100;
        int len = (int)(sr * 0.22);
        short[] s = new short[len];
        for (int i = 0; i < len; i++)
        {
            double t = (double)i / sr;
            double click = Math.Sin(2 * Math.PI * 1200 * t) * Math.Exp(-t * 80);
            double tone1 = Math.Sin(2 * Math.PI * 587.33 * t) * Math.Exp(-t * 18); // D5
            double tone2 = Math.Sin(2 * Math.PI * 880.00 * t) * Math.Exp(-t * 22); // A5
            double val = (click * 0.6 + tone1 * 0.6 + tone2 * 0.4);
            s[i] = (short)(Math.Max(-1.0, Math.Min(1.0, val)) * 26000);
        }
        WriteWav(path, s, sr);
    }

    static void GenerateHint(string path)
    {
        int sr = 44100;
        int len = (int)(sr * 0.55);
        short[] s = new short[len];
        double[] freqs = new double[] { 523.25, 659.25, 783.99, 1046.50 }; // C-E-G-C
        for (int i = 0; i < len; i++)
        {
            double t = (double)i / sr;
            double val = 0;
            for (int f = 0; f < freqs.Length; f++)
            {
                double noteDelay = f * 0.08;
                if (t >= noteDelay)
                {
                    double noteT = t - noteDelay;
                    val += Math.Sin(2 * Math.PI * freqs[f] * noteT) * Math.Exp(-noteT * 7.0);
                }
            }
            s[i] = (short)(Math.Max(-1.0, Math.Min(1.0, val * 0.4)) * 22000);
        }
        WriteWav(path, s, sr);
    }

    static void GenerateStar(string path)
    {
        int sr = 44100;
        int len = (int)(sr * 0.45);
        short[] s = new short[len];
        double[] freqs = new double[] { 659.25, 880.00, 1174.66, 1318.51 }; // E-A-D-E
        for (int i = 0; i < len; i++)
        {
            double t = (double)i / sr;
            double val = 0;
            for (int f = 0; f < freqs.Length; f++)
            {
                double noteDelay = f * 0.07;
                if (t >= noteDelay)
                {
                    double noteT = t - noteDelay;
                    val += Math.Sin(2 * Math.PI * freqs[f] * noteT) * Math.Exp(-noteT * 8.0);
                }
            }
            s[i] = (short)(Math.Max(-1.0, Math.Min(1.0, val * 0.45)) * 24000);
        }
        WriteWav(path, s, sr);
    }

    static void GenerateLevelStart(string path)
    {
        int sr = 44100;
        int len = (int)(sr * 0.6);
        short[] s = new short[len];
        double[] notes = new double[] { 440.0, 554.37, 659.25 }; // A major
        for (int i = 0; i < len; i++)
        {
            double t = (double)i / sr;
            double val = 0;
            for (int n = 0; n < notes.Length; n++)
            {
                double dt = t - n * 0.12;
                if (dt >= 0)
                {
                    val += Math.Sin(2 * Math.PI * notes[n] * dt) * Math.Exp(-dt * 4.5);
                }
            }
            s[i] = (short)(Math.Max(-1.0, Math.Min(1.0, val * 0.45)) * 22000);
        }
        WriteWav(path, s, sr);
    }

    static void GenerateVictory(string path)
    {
        int sr = 44100;
        int len = (int)(sr * 1.8);
        short[] s = new short[len];
        double[,] notes = new double[,]
        {
            { 0.00, 523.25, 0.22 },
            { 0.22, 659.25, 0.22 },
            { 0.44, 783.99, 0.25 },
            { 0.70, 1046.50, 1.05 },
            { 0.70, 523.25, 1.05 },
            { 0.70, 659.25, 1.05 }
        };

        for (int i = 0; i < len; i++)
        {
            double t = (double)i / sr;
            double val = 0;
            for (int n = 0; n < 6; n++)
            {
                double noteTime = notes[n, 0];
                double noteFreq = notes[n, 1];
                double noteDur = notes[n, 2];
                if (t >= noteTime && t <= noteTime + noteDur)
                {
                    double dt = t - noteTime;
                    double env = Math.Min(1.0, dt / 0.03) * Math.Exp(-dt * 1.8);
                    val += (Math.Sin(2 * Math.PI * noteFreq * dt) + 0.3 * Math.Sin(4 * Math.PI * noteFreq * dt)) * env;
                }
            }
            s[i] = (short)(Math.Max(-1.0, Math.Min(1.0, val * 0.32)) * 26000);
        }
        WriteWav(path, s, sr);
    }

    static void GenerateBgm(string path)
    {
        int sr = 22050; // 22kHz
        int len = sr * 16; // 16 second ambient loop
        short[] s = new short[len];
        double[][] chords = new double[][]
        {
            new double[] { 261.63, 329.63, 392.00, 493.88 }, // Cmaj7
            new double[] { 220.00, 261.63, 329.63, 392.00 }, // Am7
            new double[] { 174.61, 220.00, 261.63, 329.63 }, // Fmaj7
            new double[] { 196.00, 246.94, 293.66, 392.00 }  // G
        };

        for (int i = 0; i < len; i++)
        {
            double t = (double)i / sr;
            int chordIdx = (int)(t / 4.0) % 4;
            double chordT = t % 4.0;
            double chordEnv = Math.Sin(Math.PI * (chordT / 4.0));

            double val = 0;
            double[] notes = chords[chordIdx];
            for (int n = 0; n < notes.Length; n++)
            {
                val += Math.Sin(2 * Math.PI * notes[n] * t) * 0.22;
                val += Math.Sin(Math.PI * notes[n] * t) * 0.12;
            }

            int arpStep = (int)(t / 0.5);
            double arpT = t % 0.5;
            double arpFreq = notes[arpStep % notes.Length] * 2.0;
            double arpEnv = Math.Exp(-arpT * 6.0);
            val += Math.Sin(2 * Math.PI * arpFreq * arpT) * arpEnv * 0.18;

            val *= chordEnv;
            double loopFade = 1.0;
            if (t < 0.5) loopFade = t / 0.5;
            if (t > 15.5) loopFade = (16.0 - t) / 0.5;
            val *= loopFade;

            s[i] = (short)(Math.Max(-1.0, Math.Min(1.0, val * 0.5)) * 16000);
        }
        WriteWav(path, s, sr);
    }
}
