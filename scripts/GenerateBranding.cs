using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public class BrandingGenerator
{
    public static void Main()
    {
        string outDir = @"assets\images";
        GenerateLogo(Path.Combine(outDir, "logo.png"));
        GenerateBanner(Path.Combine(outDir, "banner.png"));
        Console.WriteLine("Branding generated.");
    }

    static void GenerateLogo(string path)
    {
        int size = 512;
        using (Bitmap bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;

            // Rounded gradient badge
            using (GraphicsPath badge = new GraphicsPath())
            {
                int r = 110;
                badge.AddArc(20, 20, r, r, 180, 90);
                badge.AddArc(size - 20 - r, 20, r, r, 270, 90);
                badge.AddArc(size - 20 - r, size - 20 - r, r, r, 0, 90);
                badge.AddArc(20, size - 20 - r, r, r, 90, 90);
                badge.CloseFigure();

                using (LinearGradientBrush bg = new LinearGradientBrush(new Point(0, 0), new Point(size, size), Color.FromArgb(74, 30, 140), Color.FromArgb(20, 10, 60)))
                {
                    g.FillPath(bg, badge);
                }
                using (Pen borderPen = new Pen(Color.FromArgb(255, 215, 0), 8f))
                {
                    g.DrawPath(borderPen, badge);
                }
            }

            // 4 Interlocking Puzzle Pieces in 2x2 with 3D bevels
            DrawInterlockingPiece(g, 110, 110, 145, Color.FromArgb(255, 90, 95));
            DrawInterlockingPiece(g, 255, 110, 145, Color.FromArgb(45, 190, 240));
            DrawInterlockingPiece(g, 110, 255, 145, Color.FromArgb(255, 180, 0));
            DrawInterlockingPiece(g, 255, 255, 145, Color.FromArgb(80, 220, 120));

            // Sparkling Star in center
            DrawStar(g, size / 2, size / 2, 28, 12, Color.White);

            bmp.Save(path, ImageFormat.Png);
        }
    }

    static void GenerateBanner(string path)
    {
        int w = 1200, h = 600;
        using (Bitmap bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb))
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            using (LinearGradientBrush bg = new LinearGradientBrush(new Point(0, 0), new Point(w, h), Color.FromArgb(25, 15, 55), Color.FromArgb(10, 8, 25)))
            {
                g.FillRectangle(bg, 0, 0, w, h);
            }

            // Ambient glowing orbs
            using (GraphicsPath orb = new GraphicsPath())
            {
                orb.AddEllipse(w / 2 - 300, -100, 600, 600);
                using (PathGradientBrush pgb = new PathGradientBrush(orb))
                {
                    pgb.CenterColor = Color.FromArgb(80, 140, 80, 240);
                    pgb.SurroundColors = new Color[] { Color.FromArgb(0, 0, 0, 0) };
                    g.FillPath(pgb, orb);
                }
            }

            bmp.Save(path, ImageFormat.Png);
        }
    }

    static void DrawInterlockingPiece(Graphics g, int x, int y, int s, Color baseCol)
    {
        Color darkCol = Color.FromArgb(baseCol.A, (int)(baseCol.R * 0.65), (int)(baseCol.G * 0.65), (int)(baseCol.B * 0.65));
        using (GraphicsPath p = new GraphicsPath())
        {
            p.AddRectangle(new Rectangle(x + 4, y + 4, s - 8, s - 8));
            using (LinearGradientBrush fill = new LinearGradientBrush(new Point(x, y), new Point(x + s, y + s), baseCol, darkCol))
            {
                g.FillPath(fill, p);
            }
            using (Pen highPen = new Pen(Color.FromArgb(140, 255, 255, 255), 4f))
            {
                g.DrawLine(highPen, x + 6, y + 6, x + s - 6, y + 6);
                g.DrawLine(highPen, x + 6, y + 6, x + 6, y + s - 6);
            }
            using (Pen shadowPen = new Pen(Color.FromArgb(120, 0, 0, 0), 4f))
            {
                g.DrawLine(shadowPen, x + s - 6, y + 6, x + s - 6, y + s - 6);
                g.DrawLine(shadowPen, x + 6, y + s - 6, x + s - 6, y + s - 6);
            }
        }
    }

    static void DrawStar(Graphics g, int cx, int cy, int rOuter, int rInner, Color col)
    {
        PointF[] pts = new PointF[8];
        for (int i = 0; i < 8; i++)
        {
            double r = (i % 2 == 0) ? rOuter : rInner;
            double angle = i * Math.PI / 4.0;
            pts[i] = new PointF((float)(cx + r * Math.Cos(angle)), (float)(cy + r * Math.Sin(angle)));
        }
        g.FillPolygon(new SolidBrush(col), pts);
    }
}
