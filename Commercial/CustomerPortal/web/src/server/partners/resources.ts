/**
 * Partner resources catalog — commercial marketing kit (paths under Commercial/).
 */
import fs from "fs";
import path from "path";
import { brand } from "@/lib/brand";

export interface PartnerResource {
  id: string;
  title: string;
  category: string;
  path: string;
  status: "ready" | "placeholder";
  description: string;
}

function commercialRoot(): string {
  return path.resolve(process.cwd(), "..", "..");
}

export function listPartnerResources(): PartnerResource[] {
  const root = path.join(commercialRoot(), "Partners", "Resources");
  if (!fs.existsSync(root)) fs.mkdirSync(root, { recursive: true });

  const catalog: Omit<PartnerResource, "status">[] = [
    {
      id: "marketing_kit",
      title: "Marketing Kit",
      category: "Marketing",
      path: "Partners/Resources/MARKETING_KIT.md",
      description: "Channel messaging, value props, approved claims",
    },
    {
      id: "brand",
      title: "Brand Guidelines",
      category: "Brand",
      path: "Partners/Resources/BRAND_GUIDELINES.md",
      description: "Logo usage · colors · do/don't",
    },
    {
      id: "brochure",
      title: "Product Brochures",
      category: "Sales",
      path: "Partners/Resources/PRODUCT_BROCHURE.md",
      description: "Website Professional overview for prospects",
    },
    {
      id: "email",
      title: "Email Templates",
      category: "Marketing",
      path: "Partners/Resources/EMAIL_TEMPLATES.md",
      description: "Intro · nurture · renewal partner emails",
    },
    {
      id: "social",
      title: "Social Media Kit",
      category: "Marketing",
      path: "Partners/Resources/SOCIAL_MEDIA_KIT.md",
      description: "Post copy · hashtags · asset checklist",
    },
    {
      id: "videos",
      title: "Demo Videos",
      category: "Training",
      path: "Partners/Resources/DEMO_VIDEOS.md",
      description: "Links / shot list for demo content",
    },
    {
      id: "deck",
      title: "Presentation Deck",
      category: "Sales",
      path: "Partners/Resources/PRESENTATION_DECK.md",
      description: "Partner pitch outline",
    },
    {
      id: "faq",
      title: "Sales FAQ",
      category: "Sales",
      path: "Partners/Resources/SALES_FAQ.md",
      description: "Objection handling · licensing FAQ",
    },
    {
      id: "compliance",
      title: "Compliance Guide",
      category: "Compliance",
      path: "Partners/Resources/COMPLIANCE_GUIDE.md",
      description: "Claims, risk disclosure, Core freeze rules for partners",
    },
  ];

  return catalog.map((c) => {
    const abs = path.join(commercialRoot(), ...c.path.split("/"));
    const dir = path.dirname(abs);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    if (!fs.existsSync(abs)) {
      fs.writeFileSync(
        abs,
        `# ${c.title}\n\n**Partner resource** · ${brand.productName}\n\n${c.description}\n\n## Rules\n\n- Use official brand assets only.\n- Do not claim trading performance guarantees.\n- Core Trading Engine is frozen — partners sell commercial access only.\n`,
        "utf8"
      );
    }
    return { ...c, status: "ready" as const };
  });
}
