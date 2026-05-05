export function getOwnerInitials(name: string | undefined): string {
  if (!name?.trim()) {
    return '';
  }

  return name
    .split(' ')
    .filter(Boolean)
    .map(part => part[0].toUpperCase())
    .join('');
}
