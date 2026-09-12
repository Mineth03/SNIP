import { Bell, Menu } from "lucide-react";
import { Avatar } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";

export function Topbar({
  title,
  description,
  profileName,
  profileAvatar,
  actions,
  onMenuClick,
}: {
  title: string;
  description?: string;
  profileName?: string;
  profileAvatar?: string | null;
  actions?: React.ReactNode;
  onMenuClick?: () => void;
}) {
  return (
    <header className="sticky top-0 z-20 flex items-center justify-between gap-4 border-b border-snip-border bg-white/90 px-4 py-3 backdrop-blur md:px-6">
      <div className="flex min-w-0 items-center gap-3">
        {onMenuClick ? (
          <Button
            type="button"
            variant="ghost"
            size="icon"
            className="md:hidden"
            onClick={onMenuClick}
            aria-label="Open menu"
          >
            <Menu className="h-5 w-5" />
          </Button>
        ) : null}
        <div className="min-w-0">
          <h1 className="truncate text-lg font-semibold text-snip-charcoal">
            {title}
          </h1>
          {description ? (
            <p className="truncate text-sm text-snip-muted">{description}</p>
          ) : null}
        </div>
      </div>
      <div className="flex items-center gap-2">
        {actions}
        <Button type="button" variant="ghost" size="icon" aria-label="Notifications">
          <Bell className="h-5 w-5 text-snip-muted" />
        </Button>
        {profileName ? (
          <Avatar name={profileName} src={profileAvatar} size="sm" />
        ) : null}
      </div>
    </header>
  );
}
