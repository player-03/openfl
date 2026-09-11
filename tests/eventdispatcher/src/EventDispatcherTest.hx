package;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.EventPhase;
import utest.Assert;
import utest.Test;

@:access(openfl.events.Event)
class EventDispatcherTest extends Test
{
	public function test_new_()
	{
		var dispatcher = new EventDispatcher();

		Assert.notNull(dispatcher);

		var dispatcher2 = new EventDispatcher(dispatcher);

		Assert.notNull(dispatcher2);
	}

	public function test_addEventListener()
	{
		var dispatcher = new EventDispatcher();
		dispatcher.addEventListener("event", function(_) {});

		Assert.isTrue(dispatcher.hasEventListener("event"));
	}

	public function test_dispatchEvent()
	{
		// Standard

		var caughtEvent = false;
		var correctPhase = true;
		var dispatcher = new EventDispatcher();

		var listener = function(event)
		{
			caughtEvent = true;
			correctPhase = EventPhase.AT_TARGET == event.eventPhase;
		};

		dispatcher.addEventListener("event", listener);
		var result = dispatcher.dispatchEvent(new Event("event"));
		Assert.isTrue(result);
		Assert.isTrue(caughtEvent);
		Assert.isTrue(correctPhase);

		// Capture is true, but not on display list

		var caughtEvent = false;
		var correctPhase = true;
		var dispatcher = new EventDispatcher();

		var listener = function(event:Event)
		{
			caughtEvent = true;
			// doesn't get called because capture phase
		}

		dispatcher.addEventListener("event", listener, true);
		var result = dispatcher.dispatchEvent(new Event("event"));
		Assert.isTrue(result);
		Assert.isFalse(caughtEvent);

		// First in, first out standard order

		var correctOrder = true;
		var dispatcher = new EventDispatcher();

		var listener = function(_)
		{
			correctOrder = false;
		}

		var listener2 = function(_)
		{
			correctOrder = true;
		}

		dispatcher.addEventListener("event", listener);
		dispatcher.addEventListener("event", listener2);

		Assert.isTrue(correctOrder);

		// Order by priority

		var correctOrder = true;
		var dispatcher = new EventDispatcher();

		var listener = function(_)
		{
			correctOrder = false;
		}

		var listener2 = function(_)
		{
			correctOrder = true;
		}

		dispatcher.addEventListener("event", listener2, false, 10);
		dispatcher.addEventListener("event", listener, false, 20);
		dispatcher.dispatchEvent(new Event("event"));

		Assert.isTrue(correctOrder);

		// Bubbling

		var sprite = new Sprite();
		var sprite2 = new Sprite();

		var spriteEvent = false;
		var sprite2Event = false;

		var listener = function(_)
		{
			spriteEvent = true;
			correctOrder = true;
		}

		var listener2 = function(_)
		{
			sprite2Event = true;
			correctOrder = false;
		}

		sprite.addEventListener("event", listener);
		sprite2.addEventListener("event", listener2);
		sprite.addChild(sprite2);
		sprite2.dispatchEvent(new Event("event"));

		Assert.isFalse(spriteEvent);
		Assert.isTrue(sprite2Event);

		sprite2Event = false;

		sprite2.dispatchEvent(new Event("event", true));

		Assert.isTrue(spriteEvent);
		Assert.isTrue(sprite2Event);
		Assert.isTrue(correctOrder);

		// Capture event bubbling

		var sprite = new Sprite();
		var sprite2 = new Sprite();

		var spriteEvent = false;
		var sprite2Event = false;

		var listener = function(_)
		{
			spriteEvent = true;
			correctOrder = true;
		}

		var listener2 = function(_)
		{
			sprite2Event = true;
			correctOrder = false;
		}

		sprite.addEventListener("event", listener, true);
		sprite2.addEventListener("event", listener2, true);
		sprite.addChild(sprite2);
		sprite2.dispatchEvent(new Event("event"));

		Assert.isTrue(spriteEvent);
		Assert.isFalse(sprite2Event);

		sprite2Event = false;

		sprite2.dispatchEvent(new Event("event", true));

		Assert.isTrue(spriteEvent);
		Assert.isFalse(sprite2Event);
		Assert.isTrue(correctOrder);
	}

	// public function test_hasEventListener() {}

	public function test_removeEventListener()
	{
		var dispatcher = new EventDispatcher();
		var listener = function(_) {};
		dispatcher.addEventListener("event", listener);
		dispatcher.removeEventListener("event", listener);

		Assert.isFalse(dispatcher.hasEventListener("event"));
	}

	/*public function toString () {



	}*/
	// public function test_willTrigger() {}

	public function testSimpleNestedDispatch()
	{
		var test01aCallCount = 0;
		var o = new EventDispatcher();

		var test01a = function(e:Event):Void
		{
			++test01aCallCount;
			if (test01aCallCount == 1)
			{ // avoid infinite recursion, but we still should get a second call
				o.dispatchEvent(new Event("Test01Event"));
			}
		}

		o.addEventListener("Test01Event", test01a);
		o.dispatchEvent(new Event("Test01Event"));

		Assert.equals(2, test01aCallCount);
	}

	public function testDispatchingRemainsTrue()
	{
		var test02aCallCount = 0;
		var test02Sequence:String = "";
		var o = new EventDispatcher();

		var test02b = function(e:Event):Void
		{
			test02Sequence += "b";
		}

		var test02c = function(e:Event):Void
		{
			test02Sequence += "c";
		}

		var test02a = function(e:Event):Void
		{
			test02Sequence += "a";
			++test02aCallCount;
			if (test02aCallCount == 1)
			{
				test02Sequence += "(";
				o.dispatchEvent(new Event("Test02Event"));
				test02Sequence += ")";

				// dispatching should still be true here, so this shouldn't modify the list we're traversing over
				// ...but it does...
				o.removeEventListener("Test02Event", test02b);
				o.addEventListener("Test02Event", test02c, false, 4);
				o.addEventListener("Test02Event", test02b, false, 5);
			}
		}

		// Test 02: Dispatching goes false too soon.
		// The reset of dispatching at the tail of __dispatchEvent,
		// namely the __dispatching.set (event.type, false); line,
		// is unconditional. Clearly we want to keep dispatching true
		// if we're nested, so we should only unset that if we're the
		// "outermost" dispatcher.
		o.addEventListener("Test02Event", test02a, false, 3);
		o.addEventListener("Test02Event", test02b, false, 2);
		o.addEventListener("Test02Event", test02c, false, 1);
		o.dispatchEvent(new Event("Test02Event"));

		// Assert.equals("a(abc)bc", test02Sequence);
		Assert.equals("a(abc)c", test02Sequence);
	}

	public function test_dispatchEventWithCancelableEventAndPreventDefaultCall()
	{
		var eventType = "myCustomEvent";

		var dispatcher = new EventDispatcher();
		dispatcher.addEventListener(eventType, function(event:Event):Void
		{
			// listeners without priority are called in order, so this listener
			// is called first in the AT_TARGET because it was added first.
			Assert.isFalse(event.isDefaultPrevented());
			event.preventDefault();
			Assert.isTrue(event.isDefaultPrevented());
			Assert.equals(EventPhase.AT_TARGET, event.eventPhase);
		});
		dispatcher.addEventListener(eventType, function(event:Event):Void
		{
			// listeners without priority are called in order, so this listener
			// is called second in the AT_TARGET because it was added second.
			Assert.isTrue(event.isDefaultPrevented());
			Assert.equals(EventPhase.AT_TARGET, event.eventPhase);
		});
		var event = new Event(eventType, false, true);
		var result = dispatcher.dispatchEvent(event);

		// not successful because preventDefault() was called
		Assert.isFalse(result);
		Assert.isTrue(event.isDefaultPrevented());
	}

	public function test_dispatchEventWithCancelableEventAndNoPreventDefaultCall()
	{
		var eventType = "myCustomEvent";

		var dispatcher = new EventDispatcher();
		dispatcher.addEventListener(eventType, function(event:Event):Void
		{
			// listeners without priority are called in order, so this listener
			// is called first in the AT_TARGET because it was added first.
			Assert.isFalse(event.isDefaultPrevented());
			Assert.equals(EventPhase.AT_TARGET, event.eventPhase);
		});
		dispatcher.addEventListener(eventType, function(event:Event):Void
		{
			// listeners without priority are called in order, so this listener
			// is called second in the AT_TARGET because it was added second.
			Assert.isFalse(event.isDefaultPrevented());
			Assert.equals(EventPhase.AT_TARGET, event.eventPhase);
		});
		var event = new Event(eventType, false, true);
		var result = dispatcher.dispatchEvent(event);

		// successful because preventDefault() was not called
		Assert.isTrue(result);
		Assert.isFalse(event.isDefaultPrevented());
	}

	public function test_dispatchEventWithStopPropagation()
	{
		var eventType = "myCustomEvent";

		var calledListener1 = false;
		var calledListener2 = false;
		var dispatcher = new EventDispatcher();
		dispatcher.addEventListener(eventType, function(event:Event):Void
		{
			// listeners without priority are called in order, so this listener
			// is called first in the AT_TARGET because it was added first.
			Assert.isFalse(calledListener1);
			Assert.isFalse(calledListener2);
			calledListener1 = true;
			event.stopPropagation();
			Assert.equals(EventPhase.AT_TARGET, event.eventPhase);
		});
		dispatcher.addEventListener(eventType, function(event:Event):Void
		{
			// stopPropagation() does not stop the current phase, so this
			// listener will be called.
			// listeners without priority are called in order, so this listener
			// is called second in the AT_TARGET because it was added second.
			Assert.isTrue(calledListener1);
			Assert.isFalse(calledListener2);
			calledListener2 = true;
			Assert.equals(EventPhase.AT_TARGET, event.eventPhase);
		});
		var event = new Event(eventType, false, true);
		var result = dispatcher.dispatchEvent(event);
		// successful because preventDefault() was not called
		Assert.isTrue(result);

		Assert.isTrue(calledListener1);
		Assert.isTrue(calledListener2);
	}

	public function test_dispatchEventWithStopImmediatePropagation()
	{
		var eventType = "myCustomEvent";

		var calledListener1 = false;
		var calledListener2 = false;
		var dispatcher = new EventDispatcher();
		dispatcher.addEventListener(eventType, function(event:Event):Void
		{
			// listeners without priority are called in order, so this listener
			// is called first in the AT_TARGET because it was added first.
			Assert.isFalse(calledListener1);
			Assert.isFalse(calledListener2);
			calledListener1 = true;
			event.stopImmediatePropagation();
			Assert.equals(EventPhase.AT_TARGET, event.eventPhase);
		});
		dispatcher.addEventListener(eventType, function(event:Event):Void
		{
			// stopImmediatePropagation() prevents this listener from being called
			Assert.fail();
		});
		var event = new Event(eventType, false, true);
		var result = dispatcher.dispatchEvent(event);
		// successful because preventDefault() was not called
		Assert.isTrue(result);

		Assert.isTrue(calledListener1);
		Assert.isFalse(calledListener2);
	}

	public function test_dispatchEventWithPreventDefaultAndStopPropagation()
	{
		var eventType = "myCustomEvent";

		var dispatcher = new EventDispatcher();
		dispatcher.addEventListener(eventType, function(event:Event):Void
		{
			// listeners without priority are called in order, so this listener
			// is called first in the AT_TARGET because it was added first.
			event.preventDefault();
			event.stopPropagation();
			Assert.equals(EventPhase.AT_TARGET, event.eventPhase);
		});
		var event = new Event(eventType, false, true);
		var result = dispatcher.dispatchEvent(event);
		// not successful because preventDefault() was called
		Assert.isFalse(result);
	}

	public function test_dispatchEventWithPreventDefaultAndStopImmediatePropagation()
	{
		var eventType = "myCustomEvent";

		var dispatcher = new EventDispatcher();
		dispatcher.addEventListener(eventType, function(event:Event):Void
		{
			// listeners without priority are called in order, so this listener
			// is called first in the AT_TARGET because it was added first.
			event.preventDefault();
			event.stopImmediatePropagation();
			Assert.equals(EventPhase.AT_TARGET, event.eventPhase);
		});
		var event = new Event(eventType, false, true);
		var result = dispatcher.dispatchEvent(event);
		// not successful because preventDefault() was called
		Assert.isFalse(result);
	}

	public function test_redispatchEventFromListener()
	{
		var eventType = "myCustomEvent";

		var event1a:Event = null;
		var event1b:Event = null;
		var event2:Event = null;
		var dispatcher1 = new EventDispatcher();
		var dispatcher2 = new EventDispatcher();
		dispatcher1.addEventListener(eventType, function(event:Event):Void
		{
			event1a = event;
			Assert.isNull(event1b);
			Assert.isNull(event2);

			// set these flags because they need to be cleared when redispatched
			event1a.preventDefault();
			event1a.stopPropagation();
			dispatcher2.dispatchEvent(event1a);
		});
		dispatcher1.addEventListener(eventType, function(event:Event):Void
		{
			event1b = event;
			Assert.equals(event1a, event1b);
			Assert.notNull(event2);
			Assert.notEquals(event2, event1b);

			// this listener is called after the redispatch
			// make sure that no properties were affected by the redispatch
			Assert.equals(eventType, event1b.type);
			Assert.equals(dispatcher1, event1b.target);
			Assert.equals(dispatcher1, event1b.currentTarget);
			Assert.equals(EventPhase.AT_TARGET, event1b.eventPhase);
			Assert.isTrue(event1b.bubbles);
			Assert.isTrue(event1b.cancelable);
			Assert.isTrue(event1b.isDefaultPrevented());
			#if !flash
			Assert.isTrue(event1b.__isCanceled);
			#end
		});
		dispatcher2.addEventListener(eventType, function(event:Event):Void
		{
			event2 = event;

			Assert.notEquals(event1a, event2);
			Assert.isNull(event1b);

			Assert.equals(eventType, event2.type);
			Assert.equals(dispatcher2, event2.target);
			Assert.equals(dispatcher2, event2.currentTarget);
			Assert.equals(EventPhase.AT_TARGET, event2.eventPhase);
			Assert.isTrue(event2.bubbles);
			Assert.isTrue(event2.cancelable);
			Assert.isFalse(event2.isDefaultPrevented());
			#if !flash
			Assert.isFalse(event2.__isCanceled);
			#end
		});
		var event = new Event(eventType, true, true);
		var result = dispatcher1.dispatchEvent(event);
		// the original dispatch is cancelled, so expect false
		// the redispatch is not cancelled, and should not affect the first
		Assert.isFalse(result);

		Assert.notNull(event1a);
		Assert.notNull(event1b);
		Assert.notNull(event2);
	}
}
