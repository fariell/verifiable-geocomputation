// ===========================================================================
//  GeoProofBench · P-001
//  文件 : formal/dafny/P001_horn_slope.dfy
//  算子 : Horn (1981) 3x3 有限差分坡度
//  覆盖 : GPB-001(坡度非负/平坦为零)、GPB-002(均匀斜面)、
//         GPB-019 的一阶部分(有限差分算子在平面上的精确性)
//  环境 : Dafny 4.11 · 验证命令 dafny verify P001_horn_slope.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  为什么先做这一条(科学动机)
//  --------------------------
//  Phase 1 实验给出一组刺眼的对比:
//      一阶算子(坡度 / 坡向)在参考实现之间  corr > 0.9999
//      二阶算子(曲率)                        corr  = 0.157
//
//  一个必须回答的追问是:一阶算子的"一致性"是经验的巧合,还是可以从算子
//  的代数结构里**证明**出来?本文件给出第一组肯定回答——在精确算术(real)
//  下,Horn 算子的四条基本性质可以从定义直接推出,不依赖任何经验假设。
//
//  反过来,这也划出了本方向的真实边界:这些性质之所以可证,是因为一阶
//  差分是**线性**的、且**不依赖中心元 e**。曲率算子显式依赖 e,是二阶
//  差分,噪声在二阶差分上被放大 O(1/w²)。Phase 1 那个 0.157 不是实现
//  bug,是算子本身的病态——这正是"可验证空间计算"要正面处理的科学缺口。
//  (形式化曲率算子 → 见 P-002,对应 GPB-005/006/007/020)
//
// ===========================================================================

module HornSlope {

  // ------------------------------------------------------------------
  // 3x3 窗口约定(行偏移 q 向下为正,符合栅格惯例)
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  // 注意:中心元 e 在 Horn 一阶差分中的权为 0,**不出现在算子签名里**。
  // 这不是省略,而是算子的结构性质——见文末"为什么二阶不行"。
  // ------------------------------------------------------------------

  // ---- 分子(尚未除以格网间距)----
  function NumDx(a: real, b: real, c: real, d: real, f: real,
                 g: real, h: real, i: real): real
  { (c + 2.0*f + i) - (a + 2.0*d + g) }

  function NumDy(a: real, b: real, c: real, d: real, f: real,
                 g: real, h: real, i: real): real
  { (g + 2.0*h + i) - (a + 2.0*b + c) }

  // ---- 一阶偏导估计(单位:m/m,无量纲)----
  function DzDx(a: real, b: real, c: real, d: real, f: real,
                g: real, h: real, i: real, w: real): real
    requires w > 0.0
  { NumDx(a, b, c, d, f, g, h, i) / (8.0*w) }

  function DzDy(a: real, b: real, c: real, d: real, f: real,
                g: real, h: real, i: real, w: real): real
    requires w > 0.0
  { NumDy(a, b, c, d, f, g, h, i) / (8.0*w) }

  function Sq(x: real): real
  { x * x }

  // 坡度 = 梯度模长。这里取**平方**而非开方:real 域上 sqrt 会引入超越
  // 函数,破坏 SMT 可判定性;而"坡度非负/为零"这类性质在平方层面已完全
  // 表达,且平方是多项式,可判定。(需要真值比较时再单独引 sqrt 公理。)
  function SlopeSq(a: real, b: real, c: real, d: real, f: real,
                   g: real, h: real, i: real, w: real): real
    requires w > 0.0
  { Sq(DzDx(a, b, c, d, f, g, h, i, w)) + Sq(DzDy(a, b, c, d, f, g, h, i, w)) }

  // ---- 域上除法引理:(x*y)/y == x,当 y != 0 ----
  lemma DivCancel(x: real, y: real)
    requires y != 0.0
    ensures (x * y) / y == x
  { }

  // ==================================================================
  // GPB-001 · 平坦面的坡度恒为零
  // ==================================================================
  lemma FlatSlopeZero(C: real, w: real)
    requires w > 0.0
    ensures DzDx(C, C, C, C, C, C, C, C, w) == 0.0
    ensures DzDy(C, C, C, C, C, C, C, C, w) == 0.0
    ensures SlopeSq(C, C, C, C, C, C, C, C, w) == 0.0
  {
    // 正权之和 = 4,负权之和 = 4 → 常数项精确抵消
    assert NumDx(C, C, C, C, C, C, C, C) == 0.0;
    assert NumDy(C, C, C, C, C, C, C, C) == 0.0;
  }

  // ==================================================================
  // GPB-001 · 坡度非负(任意高程构型)
  // ==================================================================
  lemma SlopeSqNonneg(a: real, b: real, c: real, d: real, f: real,
                      g: real, h: real, i: real, w: real)
    requires w > 0.0
    ensures SlopeSq(a, b, c, d, f, g, h, i, w) >= 0.0
  {
    assert Sq(DzDx(a, b, c, d, f, g, h, i, w)) >= 0.0;
    assert Sq(DzDy(a, b, c, d, f, g, h, i, w)) >= 0.0;
  }

  // ==================================================================
  // GPB-002 + GPB-019(一阶部分)· 平面上的精确性
  //
  // 设真实地表为平面 z(x,y) = A*x + B*y + C,以间距 w 采样成 3x3 窗口。
  // 则 Horn 有限差分**精确**恢复 A 与 B —— 不是"渐进一致",是恒等。
  //
  // 这条是本文件最硬的一条:它说明一阶算子的一致性不是经验巧合。
  // (GPB-019 的完整陈述还要求 w → 0 时二阶及以上的收敛性,那需要
  //  实分析工具,留待 P-003。)
  // ==================================================================
  function Plane(A: real, B: real, C: real, w: real, p: real, q: real): real
  { A*(p*w) + B*(q*w) + C }

  lemma PlanarExact(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures DzDx(Plane(A,B,C,w,-1.0,-1.0), Plane(A,B,C,w,0.0,-1.0), Plane(A,B,C,w,1.0,-1.0),
                 Plane(A,B,C,w,-1.0,0.0),  Plane(A,B,C,w,1.0,0.0),
                 Plane(A,B,C,w,-1.0,1.0),  Plane(A,B,C,w,0.0,1.0),  Plane(A,B,C,w,1.0,1.0),
                 w) == A
    ensures DzDy(Plane(A,B,C,w,-1.0,-1.0), Plane(A,B,C,w,0.0,-1.0), Plane(A,B,C,w,1.0,-1.0),
                 Plane(A,B,C,w,-1.0,0.0),  Plane(A,B,C,w,1.0,0.0),
                 Plane(A,B,C,w,-1.0,1.0),  Plane(A,B,C,w,0.0,1.0),  Plane(A,B,C,w,1.0,1.0),
                 w) == B
  {
    assert NumDx(Plane(A,B,C,w,-1.0,-1.0), Plane(A,B,C,w,0.0,-1.0), Plane(A,B,C,w,1.0,-1.0),
                 Plane(A,B,C,w,-1.0,0.0),  Plane(A,B,C,w,1.0,0.0),
                 Plane(A,B,C,w,-1.0,1.0),  Plane(A,B,C,w,0.0,1.0),  Plane(A,B,C,w,1.0,1.0))
           == A * (8.0*w);
    assert NumDy(Plane(A,B,C,w,-1.0,-1.0), Plane(A,B,C,w,0.0,-1.0), Plane(A,B,C,w,1.0,-1.0),
                 Plane(A,B,C,w,-1.0,0.0),  Plane(A,B,C,w,1.0,0.0),
                 Plane(A,B,C,w,-1.0,1.0),  Plane(A,B,C,w,0.0,1.0),  Plane(A,B,C,w,1.0,1.0))
           == B * (8.0*w);

    calc {
      DzDx(Plane(A,B,C,w,-1.0,-1.0), Plane(A,B,C,w,0.0,-1.0), Plane(A,B,C,w,1.0,-1.0),
           Plane(A,B,C,w,-1.0,0.0),  Plane(A,B,C,w,1.0,0.0),
           Plane(A,B,C,w,-1.0,1.0),  Plane(A,B,C,w,0.0,1.0),  Plane(A,B,C,w,1.0,1.0), w);
      == (A * (8.0*w)) / (8.0*w);
      == { DivCancel(A, 8.0*w); } A;
    }
    calc {
      DzDy(Plane(A,B,C,w,-1.0,-1.0), Plane(A,B,C,w,0.0,-1.0), Plane(A,B,C,w,1.0,-1.0),
           Plane(A,B,C,w,-1.0,0.0),  Plane(A,B,C,w,1.0,0.0),
           Plane(A,B,C,w,-1.0,1.0),  Plane(A,B,C,w,0.0,1.0),  Plane(A,B,C,w,1.0,1.0), w);
      == (B * (8.0*w)) / (8.0*w);
      == { DivCancel(B, 8.0*w); } B;
    }
  }

  // ==================================================================
  // 平移不变性 · 整体高程基准移动不改变坡度
  // (这条是"坡度算子只依赖高程**差**"的形式化表述,
  //   也是垂直基准 / 大地高与正常高转换不影响坡度的理论依据)
  // ==================================================================
  lemma TranslationInvariant(a: real, b: real, c: real, d: real, f: real,
                             g: real, h: real, i: real, w: real, K: real)
    requires w > 0.0
    ensures DzDx(a+K, b+K, c+K, d+K, f+K, g+K, h+K, i+K, w) == DzDx(a, b, c, d, f, g, h, i, w)
    ensures DzDy(a+K, b+K, c+K, d+K, f+K, g+K, h+K, i+K, w) == DzDy(a, b, c, d, f, g, h, i, w)
  {
    assert NumDx(a+K, b+K, c+K, d+K, f+K, g+K, h+K, i+K) == NumDx(a, b, c, d, f, g, h, i);
    assert NumDy(a+K, b+K, c+K, d+K, f+K, g+K, h+K, i+K) == NumDy(a, b, c, d, f, g, h, i);
  }

  // ==================================================================
  // 镜像反对称性 · 左右镜像使 dz/dx 变号、dz/dy 不变(反之亦然)
  // (地形算子在坐标反射下的行为,是"算子是否与坐标系约定无关"的
  //   第一块试金石;坡向算子的手性 bug 大多栽在这里)
  // ==================================================================
  lemma MirrorDxAntisym(a: real, b: real, c: real, d: real, f: real,
                        g: real, h: real, i: real, w: real)
    requires w > 0.0
    ensures DzDx(c, b, a, f, d, i, h, g, w) == -DzDx(a, b, c, d, f, g, h, i, w)
  {
    assert NumDx(c, b, a, f, d, i, h, g) == -NumDx(a, b, c, d, f, g, h, i);
  }

  lemma MirrorDyAntisym(a: real, b: real, c: real, d: real, f: real,
                        g: real, h: real, i: real, w: real)
    requires w > 0.0
    ensures DzDy(g, h, i, d, f, a, b, c, w) == -DzDy(a, b, c, d, f, g, h, i, w)
  {
    assert NumDy(g, h, i, d, f, a, b, c) == -NumDy(a, b, c, d, f, g, h, i);
  }

  // ==================================================================
  // 尺度线性 · 高程整体缩放 k 倍,梯度缩放 k 倍
  // (单位换算 m → ft 不改变算子结构,只作用于输出)
  // ==================================================================
  lemma ScaleLinear(a: real, b: real, c: real, d: real, f: real,
                    g: real, h: real, i: real, w: real, k: real)
    requires w > 0.0
    ensures DzDx(k*a, k*b, k*c, k*d, k*f, k*g, k*h, k*i, w) == k * DzDx(a, b, c, d, f, g, h, i, w)
    ensures DzDy(k*a, k*b, k*c, k*d, k*f, k*g, k*h, k*i, w) == k * DzDy(a, b, c, d, f, g, h, i, w)
  {
    assert NumDx(k*a, k*b, k*c, k*d, k*f, k*g, k*h, k*i) == k * NumDx(a, b, c, d, f, g, h, i);
    assert NumDy(k*a, k*b, k*c, k*d, k*f, k*g, k*h, k*i) == k * NumDy(a, b, c, d, f, g, h, i);
  }

  // ==================================================================
  // 为什么二阶不行(结构注记,非引理)
  // ------------------------------------------------------------------
  // 上面六条性质之所以可证,根源有两条,而曲率两条都不满足:
  //
  //   1) 一阶差分的权向量与常数向量正交(Σw⁺ = Σw⁻ = 4)
  //      → 常数项精确抵消,平移不变性成立,平坦面输出恒为 0。
  //   2) 一阶差分**不依赖中心元 e**。
  //      → 中心格点的高程噪声 δ 完全不进入输出。
  //
  // 曲率(Evans / Zevenbergen–Thorne)是二阶差分:它显式依赖 e,且
  // 分母含 w²。设单格高程噪声标准差为 σ,则噪声经二阶差分放大到
  // O(σ/w²)。w = 30 m 的 SRTM 上,σ ≈ 2–5 m 的量级噪声足以让曲率
  // 的信噪比崩塌——这正是 Phase 1 实测 corr = 0.157 的机制。
  //
  // 结论:坡度的一致性**可以被证明**,曲率的一致性**必须先被定义**
  // (在什么误差模型、什么尺度和什么正则化下"一致")。后者才是
  // "可验证空间计算"真正要回答的问题,也是 P-002 的入口。
  // ==================================================================
}

method Main() {
  print "GeoProofBench P-001 — Horn 坡度算子的六条性质\n";
  print "全部由编译期验证:dafny verify P001_horn_slope.dfy\n";
}
