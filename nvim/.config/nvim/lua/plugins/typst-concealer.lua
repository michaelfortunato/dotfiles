-- FIXME: There is something that make this plugin slow on floating windows
-- FIXME: Typst concealing messing up fixed cursor on <c-u> <c-d>
-- Your treesitter math detection setup my custom concealer code
function typst_concealer()
  local MATH_NODES = {
    math = true,
    equation = true,
    display_math = true,
    inline_math = true,
  }

  local TEXT_NODES = {
    text = true,
    document = true,
    markup = true,
    strong = true,
    emph = true,
  }

  local CODE_NODES = {
    code = true,
    raw = true,
    code_block = true,
  }

  local function in_mathzone()
    local node = vim.treesitter.get_node({ ignore_injections = false })
    while node do
      if MATH_NODES[node:type()] then
        return true
      elseif TEXT_NODES[node:type()] or CODE_NODES[node:type()] then
        return false
      end
      node = node:parent()
    end
    return false
  end

  -- Complete symbol mappings for Typst concealer
  local symbol_map = {
    -- Greek letters (lowercase)
    alpha = "α",
    beta = "β",
    gamma = "γ",
    delta = "δ",
    epsilon = "ε",
    zeta = "ζ",
    eta = "η",
    theta = "θ",
    iota = "ι",
    kappa = "κ",
    lambda = "λ",
    mu = "μ",
    nu = "ν",
    xi = "ξ",
    pi = "π",
    rho = "ρ",
    sigma = "σ",
    tau = "τ",
    upsilon = "υ",
    phi = "φ",
    chi = "χ",
    psi = "ψ",
    omega = "ω",

    -- Greek letters (uppercase)
    Alpha = "Α",
    Beta = "Β",
    Gamma = "Γ",
    Delta = "Δ",
    Epsilon = "Ε",
    Zeta = "Ζ",
    Eta = "Η",
    Theta = "Θ",
    Iota = "Ι",
    Kappa = "Κ",
    Lambda = "Λ",
    Mu = "Μ",
    Nu = "Ν",
    Xi = "Ξ",
    Pi = "Π",
    Rho = "Ρ",
    Sigma = "Σ",
    Tau = "Τ",
    Upsilon = "Υ",
    Phi = "Φ",
    Chi = "Χ",
    Psi = "Ψ",
    Omega = "Ω",

    -- Blackboard bold (number sets) - INCLUDING EE!
    AA = "𝔸",
    BB = "𝔹",
    CC = "ℂ",
    DD = "𝔻",
    EE = "𝔼",
    FF = "𝔽",
    GG = "𝔾",
    HH = "ℍ",
    II = "𝕀",
    JJ = "𝕁",
    KK = "𝕂",
    LL = "𝕃",
    MM = "𝕄",
    NN = "ℕ",
    OO = "𝕆",
    PP = "ℙ",
    QQ = "ℚ",
    RR = "ℝ",
    SS = "𝕊",
    TT = "𝕋",
    UU = "𝕌",
    VV = "𝕍",
    WW = "𝕎",
    XX = "𝕏",
    YY = "𝕐",
    ZZ = "ℤ",

    -- bold letters
    ["upright(bold(A))"] = "𝐀",
    ["upright(bold(B))"] = "𝐁",
    ["upright(bold(C))"] = "𝐂",
    ["upright(bold(D))"] = "𝐃",
    ["upright(bold(E))"] = "𝐄",
    ["upright(bold(F))"] = "𝐅",
    ["upright(bold(G))"] = "𝐆",
    ["upright(bold(H))"] = "𝐇",
    ["upright(bold(I))"] = "𝐈",
    ["upright(bold(J))"] = "𝐉",
    ["upright(bold(K))"] = "𝐊",
    ["upright(bold(L))"] = "𝐋",
    ["upright(bold(M))"] = "𝐌",
    ["upright(bold(N))"] = "𝐍",
    ["upright(bold(O))"] = "𝐎",
    ["upright(bold(P))"] = "𝐏",
    ["upright(bold(Q))"] = "𝐐",
    ["upright(bold(R))"] = "𝐑",
    ["upright(bold(S))"] = "𝐒",
    ["upright(bold(T))"] = "𝐓",
    ["upright(bold(U))"] = "𝐔",
    ["upright(bold(V))"] = "𝐕",
    ["upright(bold(W))"] = "𝐖",
    ["upright(bold(X))"] = "𝐗",
    ["upright(bold(Y))"] = "𝐘",
    ["upright(bold(Z))"] = "𝐙",
    -- Calligraphic Letters (Lower case)
    ["upright(bold(a))"] = "𝐚",
    ["upright(bold(b))"] = "𝐛",
    ["upright(bold(c))"] = "𝐜",
    ["upright(bold(d))"] = "𝐝",
    ["upright(bold(e))"] = "𝐞",
    ["upright(bold(f))"] = "𝐟",
    ["upright(bold(g))"] = "𝐠",
    ["upright(bold(h))"] = "𝐡",
    ["upright(bold(i))"] = "𝐢",
    ["upright(bold(j))"] = "𝐣",
    ["upright(bold(k))"] = "𝐤",
    ["upright(bold(l))"] = "𝐥",
    ["upright(bold(m))"] = "𝐦",
    ["upright(bold(n))"] = "𝐧",
    ["upright(bold(o))"] = "𝐨",
    ["upright(bold(p))"] = "𝐩",
    ["upright(bold(q))"] = "𝐪",
    ["upright(bold(r))"] = "𝐫",
    ["upright(bold(s))"] = "𝐬",
    ["upright(bold(t))"] = "𝐭",
    ["upright(bold(u))"] = "𝐮",
    ["upright(bold(v))"] = "𝐯",
    ["upright(bold(w))"] = "𝐰",
    ["upright(bold(x))"] = "𝐱",
    ["upright(bold(y))"] = "𝐲",
    ["upright(bold(z))"] = "𝐳",

    -- Calligraphic Letters
    ["cal(A)"] = "𝒜",
    ["cal(B)"] = "ℬ",
    ["cal(C)"] = "𝒞",
    ["cal(D)"] = "𝒟",
    ["cal(E)"] = "ℰ",
    ["cal(F)"] = "ℱ",
    ["cal(G)"] = "𝒢",
    ["cal(H)"] = "ℋ",
    ["cal(I)"] = "ℐ",
    ["cal(J)"] = "𝒥",
    ["cal(K)"] = "𝒦",
    ["cal(L)"] = "ℒ",
    ["cal(M)"] = "ℳ",
    ["cal(N)"] = "𝒩",
    ["cal(O)"] = "𝒪",
    ["cal(P)"] = "𝒫",
    ["cal(Q)"] = "𝒬",
    ["cal(R)"] = "ℛ",
    ["cal(S)"] = "𝒮",
    ["cal(T)"] = "𝒯",
    ["cal(U)"] = "𝒰",
    ["cal(V)"] = "𝒱",
    ["cal(W)"] = "𝒲",
    ["cal(X)"] = "𝒳",
    ["cal(Y)"] = "𝒴",
    ["cal(Z)"] = "𝒵",
    -- Calligraphic letters lower case
    ["cal(a)"] = "𝒶",
    ["cal(b)"] = "𝒷",
    ["cal(c)"] = "𝒸",
    ["cal(d)"] = "𝒹",
    ["cal(e)"] = "ℯ",
    ["cal(f)"] = "𝒻",
    ["cal(g)"] = "ℊ",
    ["cal(h)"] = "𝒽",
    ["cal(i)"] = "𝒾",
    ["cal(j)"] = "𝒿",
    ["cal(k)"] = "𝓀",
    ["cal(l)"] = "𝓁",
    ["cal(m)"] = "𝓂",
    ["cal(n)"] = "𝓃",
    ["cal(o)"] = "ℴ",
    ["cal(p)"] = "𝓅",
    ["cal(q)"] = "𝓆",
    ["cal(r)"] = "𝓇",
    ["cal(s)"] = "𝓈",
    ["cal(t)"] = "𝓉",
    ["cal(u)"] = "𝓊",
    ["cal(v)"] = "𝓋",
    ["cal(w)"] = "𝓌",
    ["cal(x)"] = "𝓍",
    ["cal(y)"] = "𝓎",
    ["cal(z)"] = "𝓏",

    -- Math operators
    times = "×",
    div = "÷",
    infinity = "∞",
    partial = "∂",
    nabla = "∇",
    integral = "∫",
    sum = "∑",
    product = "∏",
    sqrt = "√",
    cbrt = "∛",
    quad = "  ",
    qquad = "    ",

    -- Set theory & logic
    ["in"] = "∈",
    ["not.in"] = "∉",
    subset = "⊂",
    supset = "⊃",
    ["subset.eq"] = "⊆",
    ["supset.eq"] = "⊇",
    union = "∪",
    intersect = "∩",
    emptyset = "∅",
    forall = "∀",
    exists = "∃",
    nexists = "∄",
    ["and"] = "∧",
    ["or"] = "∨",
    ["not"] = "¬",
    top = "⊤",
    bot = "⊥",
    ["bar.v"] = "|",

    -- Relations
    approx = "≈",
    equiv = "≡",
    sim = "∼",
    prop = "∝",
    cong = "≅",
    ["lt.eq"] = "≤",
    ["gt.eq"] = "≥",
    ["not.eq"] = "≠",
    ["eq.triple"] = "≡",
    ["approx.eq"] = "≊",
    ["lt.not"] = "≮",
    ["gt.not"] = "≯",

    -- Arrows (basic)
    ["arrow.r"] = "→",
    ["->"] = "→",
    ["arrow.l"] = "←",
    ["arrow.u"] = "↑",
    ["arrow.d"] = "↓",
    ["arrow.l.r"] = "↔",
    ["arrow.u.d"] = "↕",
    ["arrow.ne"] = "↗",
    ["arrow.nw"] = "↖",
    ["arrow.se"] = "↘",
    ["arrow.sw"] = "↙",

    -- Double arrows
    ["arrow.r.double"] = "⇒",
    ["arrow.l.double"] = "⇐",
    ["arrow.l.r.double"] = "⇔",
    ["arrow.u.double"] = "⇑",
    ["arrow.d.double"] = "⇓",
    ["arrow.u.d.double"] = "⇕",

    -- Long arrows
    ["arrow.r.long"] = "⟶",
    ["arrow.l.long"] = "⟵",
    ["arrow.l.r.long"] = "⟷",
    ["arrow.r.long.double"] = "⟹",
    ["arrow.l.long.double"] = "⟸",
    ["arrow.l.r.long.double"] = "⟺",

    -- Curved arrows
    ["arrow.r.curve"] = "↪",
    ["arrow.l.curve"] = "↩",
    ["arrow.r.curve.ccw"] = "↻",
    ["arrow.l.curve.ccw"] = "↺",

    -- Tailed arrows
    ["arrow.r.tail"] = "↣",
    ["arrow.l.tail"] = "↢",
    ["arrow.r.tail.double"] = "⤖",
    ["arrow.l.tail.double"] = "⤙",

    -- Hooked arrows
    ["arrow.r.hook"] = "↪",
    ["arrow.l.hook"] = "↩",

    -- Misc arrows
    ["arrow.zigzag"] = "↝",
    ["arrow.squiggly"] = "⇝",
    ["arrow.dashed"] = "⇢",

    -- Additional operators
    ["plus.minus"] = "±",
    ["minus.plus"] = "∓",
    oplus = "⊕",
    ominus = "⊖",
    otimes = "⊗",
    oslash = "⊘",
    odot = "⊙",
    star = "⋆",
    ast = "∗",

    -- Big operators
    ["union.big"] = "⋃",
    ["intersect.big"] = "⋂",
    ["and.big"] = "⋀",
    ["or.big"] = "⋁",
    ["plus.big"] = "⨁",
    ["times.big"] = "⨂",
    ["dot.big"] = "⨀",

    -- Integrals
    ["integral.double"] = "∬",
    ["integral.triple"] = "∭",
    ["integral.cont"] = "∮",
    ["integral.surf"] = "∯",
    ["integral.vol"] = "∰",

    -- Dots
    dot = "·",
    dots = "…",
    ["dots.v"] = "⋮",
    ["dots.h"] = "…",
    ["dots.down"] = "⋱",
    ["dots.up"] = "⋰",
    ldots = "…",
    cdots = "⋯",
    vdots = "⋮",
    ddots = "⋱",

    -- Brackets & delimiters
    ["angle.l"] = "⟨",
    ["angle.r"] = "⟩",
    ["ceil.l"] = "⌈",
    ["ceil.r"] = "⌉",
    ["floor.l"] = "⌊",
    ["floor.r"] = "⌋",
    ["abs"] = "|",
    ["norm"] = "‖",

    -- Miscellaneous
    degree = "°",
    prime = "′",
    dprime = "″",
    tprime = "‴",
    bullet = "•",
    therefore = "∴",
    because = "∵",
    QED = "∎",
    contradiction = "⇿",

    -- Physics/Engineering
    hbar = "ℏ",
    ell = "ℓ",
    wp = "℘",
    Re = "ℜ",
    Im = "ℑ",
    aleph = "ℵ",

    -- Geometry
    parallel = "∥",
    perp = "⊥",
    angle = "∠",
    triangle = "△",
    square = "□",
    diamond = "◊",
    circle = "○",

    -- Currency & misc
    euro = "€",
    pound = "£",
    yen = "¥",
    cent = "¢",
    copyright = "©",
    registered = "®",
    trademark = "™",
    section = "§",
    paragraph = "¶",

    -- Comparison operators
    ["<<"] = "≪",
    [">>"] = "≫",
    ["<<<"] = "⋘",
    [">>>"] = "⋙",
    ["<="] = "≤",
    [">="] = "≥",
    prec = "≺",
    succ = "≻",
    ["prec.eq"] = "⪯",
    ["succ.eq"] = "⪰",

    -- Turnstiles
    vdash = "⊢",
    dashv = "⊣",
    models = "⊨",
    ["vdash.double"] = "⊩",

    -- -- Fractions (common ones)
    -- ["1/2"] = "½",
    -- ["1/3"] = "⅓",
    -- ["2/3"] = "⅔",
    -- ["1/4"] = "¼",
    -- ["3/4"] = "¾",
    -- ["1/8"] = "⅛",
    -- ["3/8"] = "⅜",
    -- ["5/8"] = "⅝",
    -- ["7/8"] = "⅞",
    --
    -- -- Fractions in parentheses
    -- ["(1/2)"] = "½",
    -- ["(1/3)"] = "⅓",
    -- ["(2/3)"] = "⅔",
    -- ["(1/4)"] = "¼",
    -- ["(3/4)"] = "¾",
    -- ["(1/8)"] = "⅛",
    -- ["(3/8)"] = "⅜",
    -- ["(5/8)"] = "⅝",
    -- ["(7/8)"] = "⅞",
    --
    -- -- Superscripts (numbers)
    -- ["^0"] = "⁰",
    -- ["^1"] = "¹",
    -- ["^2"] = "²",
    -- ["^3"] = "³",
    -- ["^4"] = "⁴",
    -- ["^5"] = "⁵",
    -- ["^6"] = "⁶",
    -- ["^7"] = "⁷",
    -- ["^8"] = "⁸",
    -- ["^9"] = "⁹",
    -- ["^+"] = "⁺",
    -- ["^-"] = "⁻",
    -- ["^="] = "⁼",
    --
    -- -- Superscripts in parentheses
    -- ["^(0)"] = "⁰",
    -- ["^(1)"] = "¹",
    -- ["^(2)"] = "²",
    -- ["^(3)"] = "³",
    -- ["^(4)"] = "⁴",
    -- ["^(5)"] = "⁵",
    -- ["^(6)"] = "⁶",
    -- ["^(7)"] = "⁷",
    -- ["^(8)"] = "⁸",
    -- ["^(9)"] = "⁹",
    -- ["^(+)"] = "⁺",
    -- ["^(-)"] = "⁻",
    -- ["^(=)"] = "⁼",
    --
    -- -- Subscripts (numbers)
    -- ["_0"] = "₀",
    -- ["_1"] = "₁",
    -- ["_2"] = "₂",
    -- ["_3"] = "₃",
    -- ["_4"] = "₄",
    -- ["_5"] = "₅",
    -- ["_6"] = "₆",
    -- ["_7"] = "₇",
    -- ["_8"] = "₈",
    -- ["_9"] = "₉",
    -- ["_+"] = "₊",
    -- ["_-"] = "₋",
    -- ["_="] = "₌",
    --
    -- -- Subscripts in parentheses
    -- ["_(0)"] = "₀",
    -- ["_(1)"] = "₁",
    -- ["_(2)"] = "₂",
    -- ["_(3)"] = "₃",
    -- ["_(4)"] = "₄",
    -- ["_(5)"] = "₅",
    -- ["_(6)"] = "₆",
    -- ["_(7)"] = "₇",
    -- ["_(8)"] = "₈",
    -- ["_(9)"] = "₉",
    -- ["_(+)"] = "₊",
    -- ["_(-)"] = "₋",
    -- ["_(=)"] = "₌",
    --
    --
    ["^0"] = "⁰",
    ["^(0)"] = "⁰",
    ["^1"] = "¹",
    ["^(1)"] = "¹",
    ["^2"] = "²",
    ["^(2)"] = "²",
    ["^3"] = "³",
    ["^(3)"] = "³",
    ["^4"] = "⁴",
    ["^(4)"] = "⁴",
    ["^5"] = "⁵",
    ["^(5)"] = "⁵",
    ["^6"] = "⁶",
    ["^(6)"] = "⁶",
    ["^7"] = "⁷",
    ["^(7)"] = "⁷",
    ["^8"] = "⁸",
    ["^(8)"] = "⁸",
    ["^9"] = "⁹",
    ["^(9)"] = "⁹",

    -- Superscript letters (limited set available in Unicode)
    ["^i"] = "ⁱ",
    ["^(i)"] = "ⁱ",
    ["^n"] = "ⁿ",
    ["^(n)"] = "ⁿ",

    -- Superscript operators
    ["^+"] = "⁺",
    ["^(+)"] = "⁺",
    ["^-"] = "⁻",
    ["^(-)"] = "⁻",
    ["^="] = "⁼",
    ["^(=)"] = "⁼",

    -- SUBSCRIPTS
    -- Numbers (0-9)
    ["_0"] = "₀",
    ["_(0)"] = "₀",
    ["_1"] = "₁",
    ["_(1)"] = "₁",
    ["_2"] = "₂",
    ["_(2)"] = "₂",
    ["_3"] = "₃",
    ["_(3)"] = "₃",
    ["_4"] = "₄",
    ["_(4)"] = "₄",
    ["_5"] = "₅",
    ["_(5)"] = "₅",
    ["_6"] = "₆",
    ["_(6)"] = "₆",
    ["_7"] = "₇",
    ["_(7)"] = "₇",
    ["_8"] = "₈",
    ["_(8)"] = "₈",
    ["_9"] = "₉",
    ["_(9)"] = "₉",

    -- Subscript letters (more available than superscripts)
    ["_a"] = "ₐ",
    ["_(a)"] = "ₐ",
    ["_e"] = "ₑ",
    ["_(e)"] = "ₑ",
    ["_h"] = "ₕ",
    ["_(h)"] = "ₕ",
    ["_i"] = "ᵢ",
    ["_(i)"] = "ᵢ",
    ["_j"] = "ⱼ",
    ["_(j)"] = "ⱼ",
    ["_k"] = "ₖ",
    ["_(k)"] = "ₖ",
    ["_l"] = "ₗ",
    ["_(l)"] = "ₗ",
    ["_m"] = "ₘ",
    ["_(m)"] = "ₘ",
    ["_n"] = "ₙ",
    ["_(n)"] = "ₙ",
    ["_o"] = "ₒ",
    ["_(o)"] = "ₒ",
    ["_p"] = "ₚ",
    ["_(p)"] = "ₚ",
    ["_r"] = "ᵣ",
    ["_(r)"] = "ᵣ",
    ["_s"] = "ₛ",
    ["_(s)"] = "ₛ",
    ["_t"] = "ₜ",
    ["_(t)"] = "ₜ",
    ["_u"] = "ᵤ",
    ["_(u)"] = "ᵤ",
    ["_v"] = "ᵥ",
    ["_(v)"] = "ᵥ",
    ["_x"] = "ₓ",
    ["_(x)"] = "ₓ",

    -- Subscript operators
    ["_+"] = "₊",
    ["_(+)"] = "₊",
    ["_-"] = "₋",
    ["_(-)"] = "₋",
    ["_="] = "₌",
    ["_(=)"] = "₌",

    -- superscript capital letters (limitted set)
    ["^A"] = "ᴬ",
    ["^(A)"] = "ᴬ",
    ["^B"] = "ᴮ",
    ["^(B)"] = "ᴮ",
    ["^D"] = "ᴰ",
    ["^(D)"] = "ᴰ",
    ["^E"] = "ᴱ",
    ["^(E)"] = "ᴱ",
    ["^G"] = "ᴳ",
    ["^(G)"] = "ᴳ",
    ["^H"] = "ᴴ",
    ["^(H)"] = "ᴴ",
    ["^I"] = "ᴵ",
    ["^(I)"] = "ᴵ",
    ["^J"] = "ᴶ",
    ["^(J)"] = "ᴶ",
    ["^K"] = "ᴷ",
    ["^(K)"] = "ᴷ",
    ["^L"] = "ᴸ",
    ["^(L)"] = "ᴸ",
    ["^M"] = "ᴹ",
    ["^(M)"] = "ᴹ",
    ["^N"] = "ᴺ",
    ["^(N)"] = "ᴺ",
    ["^O"] = "ᴼ",
    ["^(O)"] = "ᴼ",
    ["^P"] = "ᴾ",
    ["^(P)"] = "ᴾ",
    ["^R"] = "ᴿ",
    ["^(R)"] = "ᴿ",
    ["^T"] = "ᵀ",
    ["^(T)"] = "ᵀ",
    ["^U"] = "ᵁ",
    ["^(U)"] = "ᵁ",
    ["^V"] = "ⱽ",
    ["^(V)"] = "ⱽ",
    ["^W"] = "ᵂ",
    ["^(W)"] = "ᵂ",
  }

  -- Namespace for our extmarks
  local ns_id = vim.api.nvim_create_namespace("typst_concealer")

  -- Function to check if position is at word boundary
  local function is_word_boundary(line, pos)
    if pos <= 0 or pos > #line then
      return true -- start/end of line
    end
    local char = line:sub(pos, pos)
    return not char:match("[%w]") -- not alphanumeric or underscore
  end

  -- Function to find and conceal symbols in a range
  local function conceal_range(bufnr, start_row, end_row)
    -- Clear existing conceals for this range
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, start_row, end_row)

    local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row, false)

    for i, line in ipairs(lines) do
      local line_nr = start_row + i - 1

      -- Check each symbol
      for symbol, unicode in pairs(symbol_map) do
        local start_col = 1
        while true do
          local s, e = string.find(line, symbol, start_col, true) -- Plain text search
          if not s then
            break
          end

          -- Special handling for subscripts and superscripts
          local should_conceal = false
          if symbol:match("^[_%^]") then
            -- For subscripts/superscripts, only check right boundary
            should_conceal = is_word_boundary(line, e + 1)
          else
            -- For other symbols, check both boundaries
            should_conceal = is_word_boundary(line, s - 1) and is_word_boundary(line, e + 1)
          end

          if should_conceal then
            -- Check if this position is in a math zone
            local current_pos = vim.api.nvim_win_get_cursor(0)
            pcall(function()
              vim.api.nvim_win_set_cursor(0, { line_nr + 1, s - 1 })
              if in_mathzone() then
                -- Add conceal extmark
                vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_nr, s - 1, {
                  end_col = e,
                  conceal = unicode,
                })
              end
            end)
            -- Restore cursor position
            pcall(function()
              vim.api.nvim_win_set_cursor(0, current_pos)
            end)
          end

          start_col = e + 1
        end
      end
    end
  end

  -- Function to update visible concealing
  local function update_concealing()
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.bo[bufnr].filetype ~= "typst" then
      return
    end
    if vim.wo.conceallevel == 0 then
      return
    end

    -- Get visible line range
    local start_line = math.max(0, vim.fn.line("w0") - 1)
    local end_line = math.min(vim.api.nvim_buf_line_count(bufnr), vim.fn.line("w$"))

    conceal_range(bufnr, start_line, end_line)
  end

  -- Function to update current line only (for performance)
  local function update_current_line()
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.bo[bufnr].filetype ~= "typst" then
      return
    end
    if vim.wo.conceallevel == 0 then
      return
    end

    local line_nr = vim.api.nvim_win_get_cursor(0)[1] - 1
    conceal_range(bufnr, line_nr, line_nr + 1)
  end

  -- Toggle function
  local function toggle_concealing()
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.wo.conceallevel == 0 then
      vim.wo.conceallevel = 2
      update_concealing()
      vim.notify("Typst concealing enabled")
    else
      vim.wo.conceallevel = 0
      vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
      vim.notify("Typst concealing disabled")
    end
  end

  -- Set up autocommands
  local group = vim.api.nvim_create_augroup("TypstConcealer", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "typst",
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()

      -- NOTE: I fyou want it on automatically, uncomment this
      -- -- Set conceallevel if not set
      -- if vim.wo.conceallevel == 0 then
      --   vim.wo.conceallevel = 2
      -- end
      -- -- Initial concealing
      -- vim.defer_fn(update_concealing, 100) -- Small delay to ensure treesitter is ready
      if vim.wo.conceallevel == 2 then
        vim.wo.conceallevel = 0
      end

      -- Update on text changes (current line only for performance)
      vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        buffer = bufnr,
        callback = update_current_line,
      })

      -- Update on cursor movement and scrolling
      vim.api.nvim_create_autocmd({ "CursorMoved", "WinScrolled" }, {
        buffer = bufnr,
        callback = update_concealing,
      })

      -- Keymap to toggle concealing (override LazyVim's default)
      vim.keymap.set("n", "<leader>uc", toggle_concealing, {
        buffer = bufnr,
        desc = "Toggle Typst concealing",
      })

      -- Additional toggle for typst-specific
      vim.keymap.set("n", "<leader>tc", toggle_concealing, {
        buffer = bufnr,
        desc = "Toggle Typst concealing",
      })
    end,
  })
end
--- actually invoke it
typst_concealer()
return {}
