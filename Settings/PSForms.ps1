$assemblies = @(
    "System",
    "System.Drawing",
    "System.Windows.Forms",
    "System.Drawing"
)

$psforms = @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Windows.Forms;
using System.Drawing.Drawing2D;

namespace PSForms
{
    public partial class ColorGradientControl : UserControl
    {
        private System.ComponentModel.IContainer components = null;

        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        private void InitializeComponent()
        {
            this.colorDialog1 = new System.Windows.Forms.ColorDialog();
            this.label1 = new System.Windows.Forms.Label();
            this.SuspendLayout();
            //
            // colorDialog1
            //
            colorDialog1.AllowFullOpen = true;
            colorDialog1.AnyColor      = true;
            colorDialog1.FullOpen      = true;
            colorDialog1.ShowHelp      = true;
            // 
            // label1
            // 
            this.label1.AccessibleRole = System.Windows.Forms.AccessibleRole.None;
            this.label1.AutoSize = true;
            this.label1.BackColor = System.Drawing.SystemColors.Window;
            this.label1.Font = new System.Drawing.Font("Microsoft Sans Serif", 4.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label1.Location = new System.Drawing.Point(3, 2);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(24, 7);
            this.label1.TabIndex = 1;
            this.label1.Text = "label1";
            this.label1.Visible = false;
            // 
            // ColorGradientControl
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(8F, 16F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(192)))), ((int)(((byte)(255)))), ((int)(((byte)(255)))));
            this.Controls.Add(this.label1);
            this.Margin = new System.Windows.Forms.Padding(3, 4, 3, 4);
            this.Name = "ColorGradientControl";
            this.Size = new System.Drawing.Size(475, 48);
            this.Paint += new System.Windows.Forms.PaintEventHandler(this.ColorGradientControl_Paint);
            this.MouseDown += new System.Windows.Forms.MouseEventHandler(this.ColorGradientControl_MouseDown);
            this.MouseLeave += new System.EventHandler(this.ColorGradientControl_MouseLeave);
            this.MouseMove += new System.Windows.Forms.MouseEventHandler(this.ColorGradientControl_MouseMove);
            this.MouseUp += new System.Windows.Forms.MouseEventHandler(this.ColorGradientControl_MouseUp);
            this.Resize += new System.EventHandler(this.ColorGradientControl_Resize);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        private System.Windows.Forms.ColorDialog colorDialog1;
        private System.Windows.Forms.Label label1;

        //gradient management class
        Wgrad<Color> realColGrad = new Wgrad<Color>(Color.White, Color.Black);
        Wgrad<Color> tmpColGrad = new Wgrad<Color>(Color.White, Color.Black);
        gradObj<Color> hdl = null;

        private Bitmap offScreenBmp; //double buffer bitmap

        #region control event management
        public event EventHandler ColorChanging;
        public event EventHandler ColorChanged;
        protected virtual void OnColorChanging(EventArgs e)
        {
            EventHandler handler = this.ColorChanging;
            if (handler != null)
            {
                handler(this, e);
            }
        }
        protected virtual void OnColorChanged(EventArgs e)
        {
            EventHandler handler = this.ColorChanged;
            if (handler != null)
            {
                handler(this, e);
            }
        }
        #endregion


        public ColorGradientControl()
        {
            InitializeComponent();
            offScreenBmp = new Bitmap(this.Width, this.Height);
        }


        //gets gdi+ ColorBlend object
        public ColorBlend getColorBlend()
        {
            ColorBlend cb = new ColorBlend();
            gradObj<Color>[] cc = tmpColGrad.getArray();
            cb.Positions = new float[cc.Length];
            cb.Colors = new Color[cc.Length];

            for (int i = 0; i < cc.Length; i++)
            {
                cb.Positions[i] = cc[i].w;
                cb.Colors[i] = cc[i].ele;
            }
            return cb;
        }

        //Given p = 0..1 , return corresponding color
        public Color getColor(float p)
        {
            if (tmpColGrad != null)
                return getColor(p, tmpColGrad);
            else
                return getColor(p, realColGrad);
        }

        private Color getColor(float p, Wgrad<Color> CGrad)
        {
            gradObj<Color>[] COLORS = CGrad.getEle(p);
            Color C1 = COLORS[0].ele;
            float W1 = COLORS[0].w;
            Color C2 = COLORS[1].ele;
            float W2 = COLORS[1].w;
            int r;
            int g;
            int b;
            if (W1 == W2)
            {
                r = C1.R;
                g = C1.G;
                b = C1.B;
            }
            else
            {
                p = (p - W1) / (W2 - W1);
                r = (int)((float)C1.R * (1f - p) + (float)C2.R * p);
                g = (int)((float)C1.G * (1f - p) + (float)C2.G * p);
                b = (int)((float)C1.B * (1f - p) + (float)C2.B * p);
            }

            Color clr;
            clr = Color.FromArgb(r, g, b);
            return clr;

        }

        //this is the control re-paint method 
        private void redraw()
        {

            tmpColGrad = realColGrad.Clone();
            if (hdl != null)
            {
                tmpColGrad.addEle(hdl.ele, hdl.w);
            }

            Graphics g = this.CreateGraphics();
            g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.AntiAlias;
            g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;

            //Do Double Buffering
            Graphics offScreenDC;
            //
            offScreenDC = Graphics.FromImage(offScreenBmp);

            offScreenDC.TextRenderingHint = System.Drawing.Text.TextRenderingHint.AntiAlias;
            offScreenDC.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;

            offScreenDC.Clear(this.BackColor);

            if (this.BackgroundImage != null)
                offScreenDC.DrawImage(this.BackgroundImage, 0, 0);

            //USE gdi+ gradient            
            LinearGradientBrush br = new LinearGradientBrush(this.ClientRectangle, Color.Black, Color.Black, 0, false);
            ColorBlend cb = new ColorBlend();
            gradObj<Color>[] cc = tmpColGrad.getArray();
            cb.Positions = new float[cc.Length];
            cb.Colors = new Color[cc.Length];

            for (int i = 0; i < cc.Length; i++)
            {
                cb.Positions[i] = cc[i].w;
                cb.Colors[i] = cc[i].ele;
            }
            br.InterpolationColors = cb;

            offScreenDC.FillRectangle(br, this.ClientRectangle);


            // draw handles
            gradObj<Color>[] hndlColors = tmpColGrad.getArray();
            foreach (gradObj<Color> c in hndlColors)
            {
                drawHndls(c, offScreenDC);
            }

            // draw graduation lines
            for (int i = 1; i < 10; i++)
            {
                if (i == 5)
                    drawLin((float)i / 10f, 0.5f, offScreenDC);
                else
                    drawLin((float)i / 10f, 0.3f, offScreenDC);
            }

            g.DrawImageUnscaled(offScreenBmp, 0, 0);

            offScreenDC.Dispose();
            g.Dispose();

        }

        private void ColorGradientControl_Paint(object sender, PaintEventArgs e)
        {
            redraw();
        }

        // public method to initialize a gradient control 
        public void reset(Color c1, Color c2)
        {
            realColGrad = new Wgrad<Color>(c1, c2);
            redraw();
        }

        // public method to add a color in position p=0..1
        public void addColor(Color c, float p)
        {
            realColGrad.addEle(c, p);
            redraw();
        }

        public Wgrad<Color> getGrad()
        {
            return realColGrad;
        }

        private void drawHndls(gradObj<Color> c, Graphics g)
        {
            g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.AntiAlias;
            g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;

            System.Drawing.Pen myPen = new System.Drawing.Pen(System.Drawing.Color.Black, 1.0f);
            System.Drawing.Pen myPen2 = new System.Drawing.Pen(System.Drawing.Color.White, 1.0f);
            myPen2.DashStyle = System.Drawing.Drawing2D.DashStyle.DashDot;
            Brush solidBeigeBrush = new SolidBrush(c.ele);
            g.FillRectangle(solidBeigeBrush, this.Width * c.w - 3, 0, 5, this.Height * 0.8f);
            g.DrawRectangle(myPen, this.Width * c.w - 3, 0, 5, this.Height * 0.8f);
            g.DrawRectangle(myPen2, this.Width * c.w - 3, 0, 5, this.Height * 0.8f);
            myPen.Dispose();
            solidBeigeBrush.Dispose();
        }

        private void drawLin(float p, float h, Graphics g)
        {
            g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.AntiAlias;
            g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;

            System.Drawing.Pen myPen = new System.Drawing.Pen(System.Drawing.Color.Black, 1.0f);
            //Brush solidBeigeBrush = new SolidBrush(c.ele);
            //g.FillRectangle(solidBeigeBrush, this.Width * c.w - 3, 0, 5, this.Height * 0.8f);
            g.DrawLine(myPen, this.Width * p, this.Height, this.Width * p, this.Height - this.Height * h);
            myPen.Dispose();
            //solidBeigeBrush.Dispose();
        }

        private void ColorGradientControl_Resize(object sender, EventArgs e)
        {
            offScreenBmp = new Bitmap(this.Width, this.Height);
        }

        #region mouse events management
        private void ColorGradientControl_MouseDown(object sender, MouseEventArgs e)
        {
            if (e.Button == System.Windows.Forms.MouseButtons.Left)
            {
                float p = (float)e.X / (float)this.Width;
                hdl = realColGrad.delNearest(p);
            }
        }

        private void ColorGradientControl_MouseMove(object sender, MouseEventArgs e)
        {
            if (this.Width > 0)
            {
                float p = (float)e.X / (float)this.Width;

                if (p > 0.5f)
                    label1.Left = (e.X - label1.Width) - 20;
                else
                    label1.Left = e.X + 20;
                label1.Text = Math.Round(p, 3).ToString();
                //label1.BackColor = Color.FromArgb(0, 0, 0, 0);
                label1.Visible = true;
                if (e.Button == System.Windows.Forms.MouseButtons.Left)
                {
                    if (hdl != null)
                    {
                        hdl.w = p;
                    }

                    redraw();
                    OnColorChanging(e);//manage event event

                }
                //label1.Visible = true;
            }
        }

        private void ColorGradientControl_MouseUp(object sender, MouseEventArgs e)
        {
            //LEFT BTN
            if (e.Button == System.Windows.Forms.MouseButtons.Left)
            {
                if (hdl != null)
                {
                    realColGrad.addEle(hdl.ele, hdl.w);
                    hdl = null;

                    redraw();
                    OnColorChanged(e);//manage event event
                }
                return;
            }
            //RIGHT BTN
            if (e.Button == System.Windows.Forms.MouseButtons.Right)
            {
                if (hdl == null)
                {
                    float p = (float)e.X / (float)this.Width;
                    colorDialog1.Color = getColor(p, realColGrad);

                    DialogResult result = colorDialog1.ShowDialog();
                    if (result == DialogResult.OK)
                    {
                        // Set form background to the selected color.

                        //realColGrad.addEle(colorDialog1.Color, p);
                        float delta = 5f / (float)this.Width;
                        realColGrad.UpdOrAddEle(colorDialog1.Color, p, delta);
                        //realColGrad.UpdOrAddEle (colorDialog1.Color, p,0.005f);

                        redraw();
                        OnColorChanged(e);//manage event event
                    }
                }
                return;
            }


        }

        private void ColorGradientControl_MouseLeave(object sender, EventArgs e)
        {
            bool wasNull = hdl == null;
            hdl = null;
            label1.Visible = false;
            if (!wasNull)
                OnColorChanged(e);//manage event event
            redraw();
        }
        #endregion


    }

    public class gradObj<T>
    {
        public T ele { get; set; }
        public float w { get; set; }
        public gradObj(T e, float p)
        {
            ele = e;
            //clamp
            if (p > 1f)
                p = 1f;
            if (p < 0f)
                p = 0f;
            w = p;
        }
    }

    public class Wgrad<T>
    {
        List<gradObj<T>> grad = new List<gradObj<T>>();

        public Wgrad(T startElE, T endEle)
        {
            gradObj<T> start = new gradObj<T>(startElE, 0f);
            gradObj<T> end = new gradObj<T>(endEle, 1f);
            grad.Add(start);
            grad.Add(end);
        }

        static float Clamp01(float p)
        {
            if (p > 1f)
                return 1f;
            if (p < 0f)
                return 0f;
            return p;
        }

        public void UpdOrAddEle(T ele, float p, float tollerance)
        {
            if (tollerance > 0 && tollerance < 1)
            {
                int found = -1;
                for (int i = 0; i < grad.Count; i++)
                {
                    float d = Math.Abs(p - grad[i].w);
                    if (d < tollerance)
                    {
                        found = i;
                    }
                }

                if (found > -1)
                {
                    grad[found].ele = ele;
                    return;
                }
            }
            // if not found adds it:
            addEle(ele, p);
        }

        public void addEle(T ele, float p)
        {
            p = Clamp01(p);
            List<gradObj<T>> tmpgrad = new List<gradObj<T>>();
            bool added = false;
            foreach (gradObj<T> obj in grad)
            {
                if (p < obj.w && !added)
                {
                    tmpgrad.Add(new gradObj<T>(ele, p));
                    added = true;
                }
                tmpgrad.Add(obj);
            }
            grad = tmpgrad;
        }

        public gradObj<T> delNearest(float p)
        {
            gradObj<T> ret = null;
            float min = 1f;
            int found = -1;
            //jump first and last
            for (int i = 1; i < grad.Count - 1; i++)
            {
                float d = Math.Abs(p - grad[i].w);
                if (d < min)
                {
                    min = d;
                    found = i;
                }
            }
            if (found > -1)
            {
                ret = grad[found];
                grad.RemoveAt(found);
            }
            return ret;
        }

        public gradObj<T>[] getEle(float p)
        {
            p = Clamp01(p);
            gradObj<T>[] v = new gradObj<T>[2];
            if (p == 0f)
            {
                v[0] = grad[0];
                v[1] = grad[0];
                return v;
            }
            if (p == 1f)
            {
                v[0] = grad[grad.Count - 1];
                v[1] = grad[grad.Count - 1];
                return v;
            }
            gradObj<T> precobj = null;
            foreach (gradObj<T> obj in grad)
            {
                if (p == obj.w)
                {
                    v[0] = obj;
                    v[1] = obj;
                    return v;
                }
                else
                {
                    if (p < obj.w)
                    {
                        v[0] = precobj;
                        v[1] = obj;
                        return v;
                    }
                }
                precobj = obj;
            }
            return v;
        }

        public gradObj<T>[] getArray()
        {
            return grad.ToArray();
        }

        public Wgrad<T> Clone()
        {
            Wgrad<T> tmp = new Wgrad<T>(this.grad[0].ele, this.grad[this.grad.Count - 1].ele);
            for (int i = 1; i < grad.Count - 1; i++)
            {
                tmp.addEle(grad[i].ele, grad[i].w);
            }
            return tmp;
        }

    }
}
'@

Add-Type -ReferencedAssemblies $assemblies -TypeDefinition $psforms -Language CSharp