import { TestBed } from '@angular/core/testing';
import { DestroyRef, signal, WritableSignal } from '@angular/core';
import { initialize, LDClient } from 'launchdarkly-js-client-sdk';
import { fakeAsync, tick } from '@angular/core/testing';
import { FeatureFlagService } from './feature-flag.service';

jest.mock('launchdarkly-js-client-sdk', () => ({
  initialize: jest.fn(),
}));

interface MockLDClient {
  waitForInitialization: jest.Mock<Promise<void>>;
  allFlags: jest.Mock<Record<string, boolean>>;
  on: jest.Mock;
  close: jest.Mock;
  identify: jest.Mock<Promise<void>>;
}

function createMockLDClient(flags: Record<string, boolean> = {}): MockLDClient {
  return {
    waitForInitialization: jest.fn<Promise<void>, [number?]>().mockResolvedValue(undefined),
    allFlags: jest.fn<Record<string, boolean>, []>().mockReturnValue(flags),
    on: jest.fn(),
    close: jest.fn(),
    identify: jest.fn<Promise<void>, [object, string?]>().mockResolvedValue(undefined),
  };
}

function getChangeListener(client: MockLDClient): (changes: Record<string, { current: boolean }>) => void {
  const call = client.on.mock.calls.find(([event]: [string]) => event === 'change');
  return call[1];
}

describe('FeatureFlagService', () => {
  let service: FeatureFlagService;
  let mockClient: MockLDClient;
  let isInitialized: WritableSignal<boolean>;
  let user: WritableSignal<{ corpId: string; ldHash: string } | null>;
  let config: WritableSignal<{ launchDarklyClientSideId: string } | null>;
  let destroyFns: (() => void)[];

  beforeEach(() => {
    isInitialized = signal(false);
    user = signal<{ corpId: string; ldHash: string } | null>({ corpId: 'user-1', ldHash: 'hash-1' });
    config = signal<{ launchDarklyClientSideId: string } | null>({ launchDarklyClientSideId: 'ld-client-id' });
    destroyFns = [];

    mockClient = createMockLDClient();
    jest.mocked(initialize).mockReturnValue(mockClient as unknown as LDClient);

    TestBed.configureTestingModule({
      providers: [
        FeatureFlagService,
        {
          provide: UserStore,
          useValue: { isInitialized: isInitialized.asReadonly(), user: user.asReadonly() },
        },
        {
          provide: ConfigService,
          useValue: { config: config.asReadonly() },
        },
        {
          provide: DestroyRef,
          useValue: { onDestroy: (fn: () => void) => destroyFns.push(fn) },
        },
      ],
    });

    service = TestBed.inject(FeatureFlagService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('getFlag', () => {
    it('should return the default value before LD initializes', () => {
      // act
      const flag = service.getFlag('unresolved-flag', false);

      // assert
      expect(flag()).toBe(false);
    });

    it('should return a custom default value when provided', () => {
      // act
      const flag = service.getFlag('unresolved-flag', true);

      // assert
      expect(flag()).toBe(true);
    });

    it('should return the same Signal instance for the same flag key', () => {
      // act
      const first = service.getFlag('feature-x');
      const second = service.getFlag('feature-x');

      // assert
      expect(first).toBe(second);
    });

    it('should return different Signal instances for different flag keys', () => {
      // act
      const flagA = service.getFlag('flag-a');
      const flagB = service.getFlag('flag-b');

      // assert
      expect(flagA).not.toBe(flagB);
    });
  });

  describe('client initialization', () => {
    it('should not initialize the client when user store is not ready', () => {
      // act
      TestBed.flushEffects();

      // assert
      expect(initialize).not.toHaveBeenCalled();
    });

    it('should not initialize the client when config is missing', () => {
      // arrange
      config.set(null);

      // act
      isInitialized.set(true);
      TestBed.flushEffects();

      // assert
      expect(initialize).not.toHaveBeenCalled();
    });

    it('should not initialize the client when user corpId is missing', () => {
      // arrange
      user.set(null);

      // act
      isInitialized.set(true);
      TestBed.flushEffects();

      // assert
      expect(initialize).not.toHaveBeenCalled();
    });

    it('should initialize the client with correct context and options', () => {
      // act
      isInitialized.set(true);
      TestBed.flushEffects();

      // assert
      expect(initialize).toHaveBeenCalledWith(
        'ld-client-id',
        { kind: 'user', key: 'user-1' },
        expect.objectContaining({ hash: 'hash-1', evaluationReasons: true }),
      );
    });

    it('should initialize the client only once on repeated effect runs', () => {
      // arrange
      isInitialized.set(true);
      TestBed.flushEffects();

      // act — trigger effect again by changing an unrelated signal
      user.set({ corpId: 'user-2', ldHash: 'hash-2' });
      TestBed.flushEffects();

      // assert
      expect(initialize).toHaveBeenCalledTimes(1);
    });
  });

  describe('flag hydration', () => {
    it('should populate flags after waitForInitialization resolves', fakeAsync(() => {
      // arrange
      mockClient.allFlags.mockReturnValue({ 'premium': true, 'beta': false });
      const premiumFlag = service.getFlag('premium');
      const betaFlag = service.getFlag('beta');

      // act
      isInitialized.set(true);
      TestBed.flushEffects();
      tick(); // resolve waitForInitialization

      // assert
      expect(premiumFlag()).toBe(true);
      expect(betaFlag()).toBe(false);
    }));

    it('should hydrate flags requested after initialization', fakeAsync(() => {
      // arrange
      mockClient.allFlags.mockReturnValue({ 'late-flag': true });
      isInitialized.set(true);
      TestBed.flushEffects();
      tick();

      // act — flag requested after LD is ready
      const lateFlag = service.getFlag('late-flag');

      // assert
      expect(lateFlag()).toBe(true);
    }));

    it('should keep default when flag is not in LD response', fakeAsync(() => {
      // arrange
      mockClient.allFlags.mockReturnValue({});

      // act
      isInitialized.set(true);
      TestBed.flushEffects();
      tick();
      const missing = service.getFlag('nonexistent', false);

      // assert
      expect(missing()).toBe(false);
    }));

    it('should not populate flags when waitForInitialization rejects', fakeAsync(() => {
      // arrange
      mockClient.waitForInitialization.mockRejectedValue(new Error('timeout'));
      const flag = service.getFlag('feature', false);

      // act
      isInitialized.set(true);
      TestBed.flushEffects();
      tick();

      // assert
      expect(flag()).toBe(false);
      expect(mockClient.allFlags).not.toHaveBeenCalled();
    }));
  });

  describe('real-time flag changes', () => {
    it('should update flags when LD pushes changes', fakeAsync(() => {
      // arrange
      mockClient.allFlags.mockReturnValue({ 'dynamic-flag': false });
      const flag = service.getFlag('dynamic-flag');

      isInitialized.set(true);
      TestBed.flushEffects();
      tick();
      expect(flag()).toBe(false);

      // act
      const changeListener = getChangeListener(mockClient);
      changeListener({ 'dynamic-flag': { current: true } });

      // assert
      expect(flag()).toBe(true);
    }));

    it('should only update flags present in the change payload', fakeAsync(() => {
      // arrange
      mockClient.allFlags.mockReturnValue({ 'stable': true, 'changing': false });
      const stableFlag = service.getFlag('stable');
      const changingFlag = service.getFlag('changing');

      isInitialized.set(true);
      TestBed.flushEffects();
      tick();

      // act
      const changeListener = getChangeListener(mockClient);
      changeListener({ 'changing': { current: true } });

      // assert
      expect(stableFlag()).toBe(true);
      expect(changingFlag()).toBe(true);
    }));
  });

  describe('user re-identification', () => {
    it('should call identify and re-hydrate flags when user changes', fakeAsync(() => {
      // arrange
      mockClient.allFlags.mockReturnValue({ 'flag': false });
      isInitialized.set(true);
      TestBed.flushEffects();
      tick();

      const flag = service.getFlag('flag');
      expect(flag()).toBe(false);

      // act — user changes
      mockClient.allFlags.mockReturnValue({ 'flag': true });
      user.set({ corpId: 'user-2', ldHash: 'hash-2' });
      TestBed.flushEffects();
      tick(); // resolve identify promise

      // assert
      expect(mockClient.identify).toHaveBeenCalledWith(
        { kind: 'user', key: 'user-2' },
        'hash-2',
      );
      expect(flag()).toBe(true);
    }));

    it('should keep existing flag values when re-identification fails', fakeAsync(() => {
      // arrange
      mockClient.allFlags.mockReturnValue({ 'flag': true });
      isInitialized.set(true);
      TestBed.flushEffects();
      tick();

      const flag = service.getFlag('flag');
      expect(flag()).toBe(true);

      // act
      mockClient.identify.mockRejectedValue(new Error('network error'));
      user.set({ corpId: 'user-3', ldHash: 'hash-3' });
      TestBed.flushEffects();
      tick();

      // assert
      expect(flag()).toBe(true);
    }));
  });
});
