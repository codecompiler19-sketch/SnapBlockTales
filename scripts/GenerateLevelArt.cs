using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public class LevelArtGenerator
{
    public static void Main()
    {
        string outDir = @"assets\images\levels";
        Directory.CreateDirectory(outDir);

        for (int i = 1; i <= 50; i++)
        {
            string filePath = Path.Combine(outDir, string.Format("level_{0}.png", i));
            GenerateArtwork(i, filePath);
            Console.WriteLine(string.Format("Generated Level {0}/50 artwork: {1}", i, filePath));
        }
        Console.WriteLine("All 50 level artworks created successfully!");
    }

    static void GenerateArtwork(int level, string path)
    {
        int size = 1024;
        using (Bitmap bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;

            int section = ((level - 1) / 10) + 1;
            int subLevel = ((level - 1) % 10) + 1;

            switch (section)
            {
                case 1:
                    DrawNatureSection(g, subLevel, size);
                    break;
                case 2:
                    DrawWildlifeSection(g, subLevel, size);
                    break;
                case 3:
                    DrawFantasySection(g, subLevel, size);
                    break;
                case 4:
                    DrawCosmicSection(g, subLevel, size);
                    break;
                case 5:
                    DrawAncientSection(g, subLevel, size);
                    break;
            }

            // Draw a subtle artistic inner vignette & golden lighting rim
            using (GraphicsPath vignettePath = new GraphicsPath())
            {
                vignettePath.AddRectangle(new Rectangle(0, 0, size, size));
                using (PathGradientBrush pgb = new PathGradientBrush(vignettePath))
                {
                    pgb.CenterColor = Color.FromArgb(0, 0, 0, 0);
                    pgb.SurroundColors = new Color[] { Color.FromArgb(60, 10, 15, 30) };
                    g.FillRectangle(pgb, 0, 0, size, size);
                }
            }

            bmp.Save(path, ImageFormat.Png);
        }
    }

    // SECTION 1: NATURE & TRANQUIL WONDERS (Levels 1-10)
    static void DrawNatureSection(Graphics g, int sub, int size)
    {
        Color[][] skies = new Color[][]
        {
            new Color[] { Color.FromArgb(30, 80, 160), Color.FromArgb(240, 140, 80), Color.FromArgb(255, 220, 150) }, // Sunset Lake
            new Color[] { Color.FromArgb(10, 30, 80), Color.FromArgb(40, 120, 140), Color.FromArgb(160, 220, 200) }, // Emerald Forest
            new Color[] { Color.FromArgb(60, 40, 100), Color.FromArgb(180, 80, 120), Color.FromArgb(250, 180, 140) }, // Lavender Meadow
            new Color[] { Color.FromArgb(15, 45, 90), Color.FromArgb(70, 130, 180), Color.FromArgb(176, 224, 230) }, // Alpine Glacier
            new Color[] { Color.FromArgb(100, 30, 40), Color.FromArgb(220, 90, 60), Color.FromArgb(255, 200, 100) }, // Autumn Cascade
            new Color[] { Color.FromArgb(20, 60, 50), Color.FromArgb(60, 140, 100), Color.FromArgb(200, 240, 180) }, // Bamboo Sanctuary
            new Color[] { Color.FromArgb(40, 20, 70), Color.FromArgb(120, 60, 140), Color.FromArgb(240, 160, 200) }, // Cherry Blossom Peak
            new Color[] { Color.FromArgb(10, 50, 80), Color.FromArgb(0, 150, 180), Color.FromArgb(120, 230, 220) }, // Tropical Lagoon
            new Color[] { Color.FromArgb(70, 40, 20), Color.FromArgb(180, 100, 40), Color.FromArgb(250, 210, 130) }, // Golden Canyon
            new Color[] { Color.FromArgb(5, 15, 45), Color.FromArgb(30, 90, 140), Color.FromArgb(140, 200, 230) }   // Starry Mountain Night
        };

        Color[] sky = skies[(sub - 1) % skies.Length];
        using (LinearGradientBrush bgBrush = new LinearGradientBrush(new Point(0, 0), new Point(0, size), sky[0], sky[2]))
        {
            ColorBlend cb = new ColorBlend(3);
            cb.Colors = sky;
            cb.Positions = new float[] { 0.0f, 0.45f, 1.0f };
            bgBrush.InterpolationColors = cb;
            g.FillRectangle(bgBrush, 0, 0, size, size);
        }

        // Glowing Sun / Moon
        int sunX = 200 + (sub * 60) % 600;
        int sunY = 180 + (sub * 30) % 200;
        using (GraphicsPath sunP = new GraphicsPath())
        {
            sunP.AddEllipse(sunX - 100, sunY - 100, 200, 200);
            using (PathGradientBrush pgb = new PathGradientBrush(sunP))
            {
                pgb.CenterColor = Color.FromArgb(255, 255, 245, 220);
                pgb.SurroundColors = new Color[] { Color.FromArgb(0, 255, 220, 150) };
                g.FillEllipse(pgb, sunX - 140, sunY - 140, 280, 280);
            }
        }
        g.FillEllipse(new SolidBrush(Color.FromArgb(240, 255, 250, 230)), sunX - 50, sunY - 50, 100, 100);

        // Mountain Layers (Far, Mid, Near)
        DrawMountainLayer(g, size, 420, 12, Color.FromArgb(160, 40, 60, 90), sub * 17);
        DrawMountainLayer(g, size, 560, 8, Color.FromArgb(210, 25, 45, 70), sub * 31);

        // Water or Foreground Ground
        int groundY = (int)(size * 0.68);
        using (LinearGradientBrush fgBrush = new LinearGradientBrush(new Point(0, groundY), new Point(0, size), Color.FromArgb(20, 50, 80), Color.FromArgb(10, 25, 40)))
        {
            g.FillRectangle(fgBrush, 0, groundY, size, size - groundY);
        }

        // Water Reflection Ripple Lines
        using (Pen waterPen = new Pen(Color.FromArgb(90, 255, 240, 200), 2.5f))
        {
            for (int r = groundY + 30; r < size; r += 28)
            {
                int w = (int)(150 + Math.Sin(r * 0.05) * 80 + (r - groundY) * 1.5);
                g.DrawLine(waterPen, sunX - w / 2, r, sunX + w / 2, r);
            }
        }

        // Foreground Pine Trees / Silhouettes
        DrawForestSilhouettes(g, size, groundY, sub);
    }

    // SECTION 2: WILDLIFE & EXOTIC NATURE (Levels 11-20)
    static void DrawWildlifeSection(Graphics g, int sub, int size)
    {
        // Lush Savannas, Coral Reefs, Rainforests
        Color cTop = Color.FromArgb(15, 35, 60);
        Color cMid = Color.FromArgb(180, 100, 30);
        Color cBot = Color.FromArgb(240, 180, 60);

        if (sub % 2 == 0) // Oceanic / Reef
        {
            cTop = Color.FromArgb(5, 20, 50);
            cMid = Color.FromArgb(0, 110, 140);
            cBot = Color.FromArgb(30, 200, 180);
        }

        using (LinearGradientBrush lgb = new LinearGradientBrush(new Point(0, 0), new Point(0, size), cTop, cBot))
        {
            g.FillRectangle(lgb, 0, 0, size, size);
        }

        // Giant sun or light beams
        if (sub % 2 == 1) // Sunset Savanna
        {
            g.FillEllipse(new SolidBrush(Color.FromArgb(250, 255, 230, 120)), size / 2 - 150, 220, 300, 300);
            // Birds in distance
            for (int b = 0; b < 7; b++)
            {
                int bx = 200 + b * 90;
                int by = 160 + (b * 37) % 120;
                DrawBird(g, bx, by, 16 + (b % 3) * 6);
            }
            // Acacia Tree Silhouettes
            DrawAcaciaTree(g, 180, (int)(size * 0.72), 260);
            DrawAcaciaTree(g, 720, (int)(size * 0.75), 320);

            // Ground hill
            using (GraphicsPath hill = new GraphicsPath())
            {
                hill.AddBezier(0, size * 0.72f, size * 0.4f, size * 0.68f, size * 0.7f, size * 0.75f, size, size * 0.70f);
                hill.AddLine(size, size, 0, size);
                g.FillPath(new SolidBrush(Color.FromArgb(30, 15, 10)), hill);
            }
        }
        else // Coral Reef
        {
            // Caustic underwater light beams
            using (GraphicsPath beam = new GraphicsPath())
            {
                beam.AddPolygon(new Point[] { new Point(200, 0), new Point(350, 0), new Point(600, size), new Point(350, size) });
                using (LinearGradientBrush bBrush = new LinearGradientBrush(new Point(0, 0), new Point(0, size), Color.FromArgb(80, 255, 255, 255), Color.FromArgb(0, 255, 255, 255)))
                {
                    g.FillPath(bBrush, beam);
                }
            }
            DrawCoralsAndBubbles(g, size, sub);
        }
    }

    // SECTION 3: FANTASY REALMS & CASTLES (Levels 21-30)
    static void DrawFantasySection(Graphics g, int sub, int size)
    {
        // Floating Islands, Magical Castles, Glowing Crystals
        using (LinearGradientBrush bg = new LinearGradientBrush(new Point(0, 0), new Point(0, size), Color.FromArgb(35, 15, 60), Color.FromArgb(10, 10, 25)))
        {
            g.FillRectangle(bg, 0, 0, size, size);
        }

        // Giant Moon / Magic Ring
        int mx = 512, my = 320;
        using (GraphicsPath moonP = new GraphicsPath())
        {
            moonP.AddEllipse(mx - 220, my - 220, 440, 440);
            using (PathGradientBrush pgb = new PathGradientBrush(moonP))
            {
                pgb.CenterColor = Color.FromArgb(240, 230, 210, 255);
                pgb.SurroundColors = new Color[] { Color.FromArgb(0, 160, 100, 240) };
                g.FillEllipse(pgb, mx - 300, my - 300, 600, 600);
            }
        }
        g.FillEllipse(new SolidBrush(Color.FromArgb(235, 225, 255)), mx - 140, my - 140, 280, 280);

        // Planetary Ring
        using (Pen ringPen = new Pen(Color.FromArgb(140, 200, 160, 255), 14f))
        {
            g.DrawArc(ringPen, mx - 280, my - 80, 560, 160, 170, 200);
        }

        // Floating Island with Fantasy Castle
        DrawFloatingIsland(g, size / 2, (int)(size * 0.62), 520, 240);
        DrawCastleSpire(g, size / 2 - 100, (int)(size * 0.62) - 150, 70, 220);
        DrawCastleSpire(g, size / 2 + 60, (int)(size * 0.62) - 130, 60, 190);
        DrawCastleSpire(g, size / 2 - 10, (int)(size * 0.62) - 200, 90, 280);

        // Glowing crystal lights
        for (int c = 0; c < 15; c++)
        {
            int cx = 100 + (c * 73) % 824;
            int cy = 400 + (c * 51) % 450;
            g.FillEllipse(new SolidBrush(Color.FromArgb(180, 140, 220, 255)), cx, cy, 8, 8);
        }
    }

    // SECTION 4: COSMIC NEBULAE & DEEP SPACE (Levels 31-40)
    static void DrawCosmicSection(Graphics g, int sub, int size)
    {
        // Jet Black with Glowing Nebula Clouds
        g.FillRectangle(new SolidBrush(Color.FromArgb(6, 6, 16)), 0, 0, size, size);

        // Nebula cloud layers
        Color[] nebColors = new Color[] { Color.FromArgb(180, 20, 120), Color.FromArgb(40, 180, 220), Color.FromArgb(240, 140, 30), Color.FromArgb(120, 50, 220) };
        Random rnd = new Random(sub * 777);

        for (int c = 0; c < 5; c++)
        {
            int nx = rnd.Next(200, size - 200);
            int ny = rnd.Next(200, size - 200);
            int nr = rnd.Next(250, 450);

            using (GraphicsPath np = new GraphicsPath())
            {
                np.AddEllipse(nx - nr, ny - nr, nr * 2, nr * 2);
                using (PathGradientBrush pgb = new PathGradientBrush(np))
                {
                    Color col = nebColors[(sub + c) % nebColors.Length];
                    pgb.CenterColor = Color.FromArgb(110, col.R, col.G, col.B);
                    pgb.SurroundColors = new Color[] { Color.FromArgb(0, col.R, col.G, col.B) };
                    g.FillEllipse(pgb, nx - nr, ny - nr, nr * 2, nr * 2);
                }
            }
        }

        // Starfield
        for (int s = 0; s < 180; s++)
        {
            int sx = rnd.Next(0, size);
            int sy = rnd.Next(0, size);
            int sw = rnd.Next(1, 4);
            int alpha = rnd.Next(120, 255);
            g.FillEllipse(new SolidBrush(Color.FromArgb(alpha, 255, 255, 255)), sx, sy, sw, sw);
        }

        // Detailed Planet
        int px = 250 + (sub * 65) % 500;
        int py = 300 + (sub * 40) % 350;
        int pr = 160;

        using (GraphicsPath pp = new GraphicsPath())
        {
            pp.AddEllipse(px - pr, py - pr, pr * 2, pr * 2);
            using (PathGradientBrush pgb = new PathGradientBrush(pp))
            {
                pgb.CenterPoint = new PointF(px - pr * 0.35f, py - pr * 0.35f);
                pgb.CenterColor = Color.FromArgb(255, 240, 200, 160);
                pgb.SurroundColors = new Color[] { Color.FromArgb(255, 20, 15, 35) };
                g.FillPath(pgb, pp);
            }
        }

        // Planet rings
        using (Pen pRing = new Pen(Color.FromArgb(160, 240, 210, 180), 8f))
        {
            g.DrawArc(pRing, px - pr * 1.8f, py - pr * 0.45f, pr * 3.6f, pr * 0.9f, 20, 140);
        }
    }

    // SECTION 5: ANCIENT WONDERS & SACRED TEMPLES (Levels 41-50)
    static void DrawAncientSection(Graphics g, int sub, int size)
    {
        // Golden Pyramids, Mayan Temples, Taj Architecture, Aurora ruins
        Color sky1 = Color.FromArgb(40, 20, 45);
        Color sky2 = Color.FromArgb(160, 60, 40);
        Color sky3 = Color.FromArgb(240, 160, 60);

        using (LinearGradientBrush lgb = new LinearGradientBrush(new Point(0, 0), new Point(0, size), sky1, sky3))
        {
            ColorBlend cb = new ColorBlend(3);
            cb.Colors = new Color[] { sky1, sky2, sky3 };
            cb.Positions = new float[] { 0.0f, 0.45f, 1.0f };
            lgb.InterpolationColors = cb;
            g.FillRectangle(lgb, 0, 0, size, size);
        }

        // Radiant Mystic Sun / Portal
        int cx = size / 2;
        int cy = (int)(size * 0.42);
        for (int r = 1; r <= 8; r++)
        {
            using (Pen rPen = new Pen(Color.FromArgb(60, 255, 220, 140), 2f))
            {
                g.DrawEllipse(rPen, cx - r * 45, cy - r * 45, r * 90, r * 90);
            }
        }
        g.FillEllipse(new SolidBrush(Color.FromArgb(255, 255, 240, 200)), cx - 60, cy - 60, 120, 120);

        // Desert Dune waves
        int duneY = (int)(size * 0.65);
        using (GraphicsPath dune1 = new GraphicsPath())
        {
            dune1.AddBezier(0, duneY, size * 0.35f, duneY - 70, size * 0.65f, duneY + 50, size, duneY);
            dune1.AddLine(size, size, 0, size);
            g.FillPath(new SolidBrush(Color.FromArgb(190, 120, 45)), dune1);
        }

        // Great Ancient Pyramid / Temple Silhouette
        Point[] pyr = new Point[]
        {
            new Point(cx, cy + 40),
            new Point(cx - 320, (int)(size * 0.85)),
            new Point(cx + 40, (int)(size * 0.88))
        };
        g.FillPolygon(new SolidBrush(Color.FromArgb(220, 145, 55)), pyr);

        Point[] pyrShadow = new Point[]
        {
            new Point(cx, cy + 40),
            new Point(cx + 40, (int)(size * 0.88)),
            new Point(cx + 360, (int)(size * 0.83))
        };
        g.FillPolygon(new SolidBrush(Color.FromArgb(130, 70, 25)), pyrShadow);

        // Foreground Dune with palms
        using (GraphicsPath dune2 = new GraphicsPath())
        {
            dune2.AddBezier(0, size * 0.85f, size * 0.45f, size * 0.78f, size * 0.8f, size * 0.88f, size, size * 0.82f);
            dune2.AddLine(size, size, 0, size);
            g.FillPath(new SolidBrush(Color.FromArgb(90, 45, 20)), dune2);
        }
        DrawAcaciaTree(g, 140, (int)(size * 0.85), 180);
    }

    // Helper utilities
    static void DrawMountainLayer(Graphics g, int size, int yBase, int segments, Color col, int seed)
    {
        Random r = new Random(seed);
        Point[] pts = new Point[segments + 3];
        pts[0] = new Point(0, size);
        pts[1] = new Point(0, yBase);

        int step = size / segments;
        for (int i = 1; i <= segments; i++)
        {
            int px = Math.Min(size, i * step);
            int py = yBase - r.Next(60, 220);
            pts[i + 1] = new Point(px, py);
        }
        pts[segments + 2] = new Point(size, size);

        using (GraphicsPath gp = new GraphicsPath())
        {
            gp.AddPolygon(pts);
            g.FillPath(new SolidBrush(col), gp);
        }
    }

    static void DrawForestSilhouettes(Graphics g, int size, int groundY, int seed)
    {
        Random r = new Random(seed * 99);
        for (int x = 10; x < size; x += r.Next(25, 55))
        {
            int h = r.Next(70, 160);
            int baseW = r.Next(24, 45);
            Point[] tree = new Point[]
            {
                new Point(x, groundY - h),
                new Point(x - baseW / 2, groundY + 10),
                new Point(x + baseW / 2, groundY + 10)
            };
            g.FillPolygon(new SolidBrush(Color.FromArgb(230, 15, 30, 45)), tree);
        }
    }

    static void DrawBird(Graphics g, int x, int y, int wingSpan)
    {
        using (Pen p = new Pen(Color.FromArgb(200, 25, 35, 55), 2.5f))
        {
            g.DrawArc(p, x - wingSpan, y, wingSpan, wingSpan / 2, 190, 150);
            g.DrawArc(p, x, y, wingSpan, wingSpan / 2, 200, 150);
        }
    }

    static void DrawAcaciaTree(Graphics g, int x, int groundY, int height)
    {
        using (Pen trunkPen = new Pen(Color.FromArgb(40, 20, 15), 14f))
        {
            g.DrawBezier(trunkPen, x, groundY, x + 20, groundY - height * 0.4f, x - 20, groundY - height * 0.7f, x, groundY - height);
        }
        // Umbrella flat canopy
        g.FillEllipse(new SolidBrush(Color.FromArgb(35, 20, 15)), x - height * 0.65f, groundY - height - 30, height * 1.3f, 50);
        g.FillEllipse(new SolidBrush(Color.FromArgb(45, 25, 20)), x - height * 0.45f, groundY - height - 45, height * 0.9f, 40);
    }

    static void DrawCoralsAndBubbles(Graphics g, int size, int seed)
    {
        Random r = new Random(seed * 31);
        for (int b = 0; b < 25; b++)
        {
            int bx = r.Next(50, size - 50);
            int by = r.Next(100, size - 100);
            int br = r.Next(6, 22);
            g.DrawEllipse(new Pen(Color.FromArgb(160, 255, 255, 255), 2f), bx, by, br, br);
            g.FillEllipse(new SolidBrush(Color.FromArgb(80, 255, 255, 255)), bx + br / 4, by + br / 4, br / 3, br / 3);
        }

        // Colorful sea fans / coral branches at bottom
        for (int c = 0; c < 12; c++)
        {
            int cx = 50 + c * 85;
            int cy = size;
            int ch = r.Next(140, 300);
            Color coralCol = (c % 2 == 0) ? Color.FromArgb(220, 240, 80, 120) : Color.FromArgb(220, 255, 170, 40);
            using (Pen cPen = new Pen(coralCol, 12f))
            {
                cPen.StartCap = LineCap.Round;
                cPen.EndCap = LineCap.Round;
                g.DrawLine(cPen, cx, cy, cx - 30, cy - ch);
                g.DrawLine(cPen, cx - 15, cy - ch / 2, cx + 40, cy - ch * 0.85f);
            }
        }
    }

    static void DrawFloatingIsland(Graphics g, int x, int y, int w, int h)
    {
        // Island underside rocky stalactite cone
        Point[] islandUnder = new Point[]
        {
            new Point(x - w / 2, y),
            new Point(x, y + h),
            new Point(x + w / 2, y)
        };
        using (LinearGradientBrush lgb = new LinearGradientBrush(new Point(x, y), new Point(x, y + h), Color.FromArgb(45, 35, 60), Color.FromArgb(15, 10, 25)))
        {
            g.FillPolygon(lgb, islandUnder);
        }

        // Island green top
        g.FillEllipse(new SolidBrush(Color.FromArgb(50, 130, 80)), x - w / 2, y - 35, w, 70);
    }

    static void DrawCastleSpire(Graphics g, int x, int y, int w, int h)
    {
        // Base tower
        g.FillRectangle(new SolidBrush(Color.FromArgb(70, 60, 95)), x, y, w, h);
        // Spire roof
        Point[] roof = new Point[]
        {
            new Point(x + w / 2, y - (int)(h * 0.65)),
            new Point(x - 8, y),
            new Point(x + w + 8, y)
        };
        g.FillPolygon(new SolidBrush(Color.FromArgb(160, 70, 130)), roof);
        // Lit window
        g.FillRectangle(new SolidBrush(Color.FromArgb(255, 230, 130)), x + w / 2 - 6, y + 30, 12, 22);
    }
}
