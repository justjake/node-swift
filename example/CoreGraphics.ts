export class CGPoint {
  constructor(readonly x: number, readonly y: number) {}
}

export class CGSize {
  constructor(readonly width: number, readonly height: number) {}
}

export class CGRect {
  constructor(
    args:
      | { origin: CGPoint; size: CGSize }
      | {
          x: number;
          y: number;
          width: number;
          height: number;
          origin?: undefined;
          size?: undefined;
        }
  ) {
    this.origin = args.origin ?? new CGPoint(args.x, args.y);
    this.size = args.size ?? new CGSize(args.width, args.height);
  }

  origin: CGPoint;
  size: CGSize;

  contains(point: CGPoint): boolean {
    return (
      this.origin.x <= point.x &&
      point.x <= this.origin.x + this.size.width &&
      this.origin.y <= point.y &&
      point.y <= this.origin.y + this.size.height
    );
  }
}
